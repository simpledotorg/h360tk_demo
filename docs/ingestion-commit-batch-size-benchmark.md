# Ingestion Performance: Choosing a Commit Batch Size

`ingest_file_h360tk.py` writes rows to Postgres in batches instead of
committing after every single row. The batch size is controlled by the
`COMMIT_BATCH_SIZE` constant in the script (currently hardcoded to **500**).

On the hardware tested here (see [Results](#results)), all values from 1 to
50,000 landed within a fairly narrow 78–112 second range for 100,000 rows —
no dramatic winner, with values in the 100–1,000 range sitting in the flat
part of the curve and 50,000 trending clearly worse. **This is a
hardware-dependent result** — see [the note at the bottom](#note-the-optimum-depends-on-your-hardware)
before assuming it holds on a different machine.

**Guidance for picking a value:** increase the batch size only as long as it
keeps giving a **notable** speed improvement. The optimum is the smallest
value **after which further increases stop giving a meaningful speedup** —
going bigger past that point only adds risk (larger uncommitted transactions
hold more memory/WAL, and lose more work if the ingest process is
interrupted mid-file) without a real benefit.

---

## Background

Earlier versions of the ingestion script committed to Postgres after every
row (`conn.autocommit = True`), meaning every insert/update was its own
transaction. For large files this meant tens of thousands of individual
commits per file. The script now batches commits — see
`ingest_and_execute()` in [`ingest_file_h360tk.py`](../ingest_file_h360tk.py):

Each row still runs inside its own `SAVEPOINT`, so one bad row is rolled back
individually without discarding the rest of an already-processed batch.

## How to change the batch size for testing

`COMMIT_BATCH_SIZE` is currently a hardcoded constant at
[`ingest_file_h360tk.py:85`](../ingest_file_h360tk.py) — to test a
different value, edit that line directly, then restart whichever container
runs the ingest:

```bash
docker compose restart file-processor   # filebrowser / poll-based path
docker compose restart sftpgo           # SFTP/FTP path
```

## Test methodology

For each value in the list below:

1. Set `COMMIT_BATCH_SIZE` to that value in the script.
2. Restart the relevant container.
3. Ingest a representative file (ideally the same file/row-count for every
   run, so results are comparable) and time it end-to-end.
4. Record the time and the row count from the script's own
   `Successfully processed records:` summary line.
5. Confirm `0` entries under `RECORD FAILURE` in the output before trusting
   the timing.

Use the **same file** (or files of the same size/shape) for every run so the
comparison is apples-to-apples — a fresh-insert run and an
update-on-conflict run can have different costs.

### Test environment

| | |
|---|---|
| Machine | Apple M3 Pro, 12 cores, 36 GB RAM |
| OS | macOS 26.3.1 (Darwin 25.3.0, arm64) |
| Docker | Docker Desktop, engine 29.6.1, Compose v5.3.0 |
| Postgres | `simpledotorg/heart360tk-postgresql:0.4.0`, local container (via docker-compose) |
| Test file size (rows) | 100,000 (synthetic CSV, unique Patient IDs — pure inserts, not update-on-conflict) |

## Results

All 10 runs completed with 0 entries under `RECORD FAILURE` and all
100,000 rows processed successfully.

| Commit batch size | Time (HH:MM:SS) | Time (s) | Rows/sec |
|---:|---:|---:|---:|
| 1 | 00:01:34 | 94 | 1,064 |
| 5 | 00:01:20 | 80 | 1,250 |
| 10 | 00:01:18 | 78 | 1,282 |
| 50 | 00:01:38 | 98 | 1,020 |
| 100 | 00:01:40 | 100 | 1,000 |
| 500 | 00:01:42 | 102 | 980 |
| 1,000 | 00:01:42 | 102 | 980 |
| 5,000 | 00:01:44 | 104 | 962 |
| 10,000 | 00:01:48 | 108 | 926 |
| 50,000 | 00:01:52 | 112 | 893 |

## Observations

- The whole range (78s–112s) is fairly narrow — about a 40% spread from
  fastest to slowest, not an order of magnitude. On this hardware, commit
  frequency alone doesn't dominate; per-row Python/pandas iteration and the
  ~6 SQL statements executed per row appear to matter more than fsync
  overhead.
- The fastest runs were actually the small-to-mid values (5–10), not the
  largest ones. Time creeps up gradually and monotonically from 500 upward,
  suggesting a mild real cost to very large batches (bigger in-memory
  transaction, more WAL held open) rather than a benefit.
- `1` (commit every row) was not dramatically worse than the rest — only
  ~20% slower than the best value here — again pointing at local SSD fsync
  being cheap on this machine specifically. This would very likely look
  different on slower or network-attached storage.
- This was a single run per value (not averaged/repeated), so treat small
  differences (e.g. 500 vs. 1,000, both 102s) as noise rather than a real
  distinction.

## Recommendation

Based on this run, values in the **100–1,000** range are all close to
optimal and consistently the flat part of the curve, with 50,000 clearly
trending worse. The shipped default of **500** sits right in that range —
no change recommended from this data. Values below 50 look fine here too,
but carry more risk on hardware where fsync isn't as cheap (see below), so
they're not preferred as a default even though they measured fine on this
machine.

---

## Note: the optimum depends on your hardware

**Batch size is only worth tuning if it measurably helps.** The bottleneck
that batching addresses is per-row DB commit/fsync overhead — how much that
matters depends on disk speed, whether Postgres is local or over the
network, and how busy the machine is. A fast local NVMe/SSD may show almost
no difference across the whole range; a slower disk, a remote/managed
Postgres instance, or a loaded shared machine may show a much steeper
penalty for small batch sizes.

Don't assume a value that worked well in one environment is optimal in
another — run this same sweep wherever you're deploying, and pick the value
at the knee of your own curve, not a number copied from someone else's test.
