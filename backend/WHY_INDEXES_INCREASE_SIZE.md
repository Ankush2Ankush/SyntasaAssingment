# Why Indexes Increase Database Size (Even for One Month)

## Understanding Database Indexes

### What Are Indexes?

Indexes are **separate data structures** that SQLite creates to speed up queries. Think of them like an index in a book:

- **Without index**: To find "January 15, 2025" in a book, you'd read every page (full table scan)
- **With index**: The index tells you "January 15 is on page 234" (direct lookup)

### How Indexes Work

When you create an index on `tpep_pickup_datetime`:
1. SQLite reads all values from that column
2. Creates a **sorted copy** of those values
3. Stores **pointers** to the original rows
4. This sorted structure allows fast lookups

## Size Increase Breakdown

### For January Data (~3.7M trips):

**Without Indexes:**
- Raw data: ~1.5-1.7 GB
- Just the trip records

**With 6 Indexes:**
- Raw data: ~1.5-1.7 GB (unchanged)
- Index overhead: ~500MB-1GB
- **Total: ~2-2.5 GB**

### Why the Increase?

Each index stores:
1. **Indexed column values** (sorted)
   - `idx_pickup_datetime`: Stores all 3.7M datetime values
   - `idx_pulocationid`: Stores all 3.7M location IDs
   - etc.

2. **Row pointers** (to find original data)
   - Each index entry points back to the original row

3. **B-tree structure** (for fast lookups)
   - Additional overhead for the tree structure

### Example Calculation:

For `idx_pickup_datetime` on 3.7M trips:
- Each datetime: ~20 bytes
- Row pointer: ~8 bytes
- B-tree overhead: ~10%
- **Total per index**: ~3.7M × 28 bytes × 1.1 ≈ **114 MB**

For 6 indexes:
- 6 × 114 MB ≈ **684 MB** of index overhead

## Why This Is Necessary

### Performance Impact:

**Without Indexes:**
```
Query: SELECT * FROM trips WHERE tpep_pickup_datetime >= '2025-01-15'
- Scans all 3.7M rows
- Time: 5+ minutes (or timeout)
```

**With Index:**
```
Query: SELECT * FROM trips WHERE tpep_pickup_datetime >= '2025-01-15'
- Uses index to find matching rows directly
- Time: 5-30 seconds
```

### The Trade-off:

- **Space**: +500MB-1GB (one-time cost)
- **Speed**: 10-100x faster queries (ongoing benefit)
- **Worth it?**: **Absolutely!** Without indexes, queries timeout.

## Size Comparison

| Scenario | Database Size | Query Time |
|----------|--------------|------------|
| No data | 20 KB | N/A |
| January data, no indexes | ~1.7 GB | 5+ min (timeout) |
| January data, with indexes | ~2-2.5 GB | 5-30 seconds |
| 4 months data, no indexes | ~5.4 GB | 5+ min (timeout) |
| 4 months data, with indexes | ~6-7 GB | 10-60 seconds |

## Your Current Situation

Looking at your file explorer, the `nyc_taxi` file shows **8.2 MB**, which is very small. This suggests:

1. **Database might be empty or incomplete**
   - Expected size for January data: ~1.5-2 GB
   - Your file: 8.2 MB (0.008 GB)

2. **Possible reasons:**
   - Database was reset/recreated
   - Only schema created (no data loaded)
   - Different database file
   - Data not loaded yet

### What to Check:

```powershell
# Check trip count
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;"

# Check database size
(Get-Item nyc_taxi.db).Length / 1GB
```

**Expected for January data:**
- Trip count: ~3,700,000 trips
- Size: ~1.5-1.7 GB (without indexes)
- Size: ~2-2.5 GB (with indexes)

## Conclusion

**Indexes increase size because:**
1. They store sorted copies of indexed columns
2. They store pointers to original rows
3. They have B-tree structure overhead

**But this is necessary because:**
1. Without indexes, queries timeout (5+ minutes)
2. With indexes, queries complete in seconds (5-30 seconds)
3. The space cost (500MB-1GB) is worth the 10-100x speed improvement

**For your case:**
- January data: ~3.7M trips
- Without indexes: ~1.7 GB, queries timeout
- With indexes: ~2-2.5 GB, queries fast
- **The 500MB-800MB increase is necessary for performance**

## Next Steps

1. **Verify your database has data:**
   ```powershell
   sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;"
   ```

2. **If data exists, create indexes:**
   ```powershell
   .\create_indexes_local_january.ps1
   ```

3. **Expected size after indexing:**
   - Current: ~1.7 GB (if you have January data)
   - After indexes: ~2-2.5 GB
   - **Increase: ~500MB-800MB** (normal and necessary)


