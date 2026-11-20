package io.github.flysky701.cage.open;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import static io.github.flysky701.cage.open.CheckPolicy.State;

final class CheckReport {
    static final class Item {
        final String id, title, detail;
        final State state;
        final boolean advanced;

        Item(String id, String title, State state, String detail, boolean advanced) {
            this.id = id;
            this.title = title;
            this.state = state;
            this.detail = detail;
            this.advanced = advanced;
        }
    }

    final String request, fingerprint;
    final long createdElapsed, createdWall;
    final List<Item> items = new ArrayList<>();
    String location = "尚未确认出口";
    String error;

    CheckReport(String request, String fingerprint, long elapsed, long wall) {
        this.request = request;
        this.fingerprint = fingerprint;
        this.createdElapsed = elapsed;
        this.createdWall = wall;
    }

    void add(String id, String title, State state, String detail) {
        add(id, title, state, detail, false);
    }

    void add(String id, String title, State state, String detail, boolean advanced) {
        items.add(new Item(id, title, state, detail, advanced));
    }

    int count(State state) {
        int result = 0;
        for (Item item : items) if (item.state == state) result++;
        return result;
    }

    boolean allPassed() {
        return !items.isEmpty() && count(State.PASSED) == items.size();
    }

    JSONObject json() throws JSONException {
        JSONObject out = new JSONObject()
                .put("schema", 1)
                .put("request", request)
                .put("createdAt", createdWall)
                .put("mode", "measured-preflight")
                .put("authorizesLaunch", false)
                .put("location", location);
        JSONArray rows = new JSONArray();
        for (Item item : items) {
            rows.put(new JSONObject()
                    .put("id", item.id)
                    .put("title", item.title)
                    .put("state", item.state.name())
                    .put("detail", item.detail)
                    .put("advanced", item.advanced));
        }
        return out.put("checks", rows);
    }

    String summary() throws JSONException {
        JSONObject safe = json();
        safe.remove("request");
        return safe.toString(2);
    }
}
