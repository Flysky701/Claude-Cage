package io.github.flysky701.hihatsprobe;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;

public class ProbeProvider extends ContentProvider {
    @Override public boolean onCreate() { return true; }
    @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String order) {
        MatrixCursor result = new MatrixCursor(new String[]{"marker"});
        result.addRow(new Object[]{"HIHATS_PROVIDER_OK"});
        return result;
    }
    @Override public String getType(Uri uri) { return "vnd.android.cursor.item/hihats-probe"; }
    @Override public Uri insert(Uri uri, ContentValues values) { throw new UnsupportedOperationException(); }
    @Override public int delete(Uri uri, String where, String[] args) { throw new UnsupportedOperationException(); }
    @Override public int update(Uri uri, ContentValues values, String where, String[] args) { throw new UnsupportedOperationException(); }
}
