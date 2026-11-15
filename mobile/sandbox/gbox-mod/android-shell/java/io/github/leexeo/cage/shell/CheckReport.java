package io.github.leexeo.cage.shell;

import java.util.ArrayList;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

final class CheckReport {
    static final class Item {
        final String id, title, detail;
        final CheckPolicy.State state;
        final boolean advanced;
        Item(String id, String title, CheckPolicy.State state, String detail, boolean advanced) {
            this.id=id; this.title=title; this.state=state; this.detail=detail; this.advanced=advanced;
        }
    }
    final String request, fingerprint;
    final long createdElapsed, createdWall;
    final List<Item> items = new ArrayList<>();
    String location = "尚未确认出口";
    String error;
    CheckReport(String request, String fingerprint, long elapsed, long wall) {
        this.request=request; this.fingerprint=fingerprint; createdElapsed=elapsed; createdWall=wall;
    }
    void add(String id, String title, CheckPolicy.State state, String detail) { add(id,title,state,detail,false); }
    void add(String id, String title, CheckPolicy.State state, String detail, boolean advanced) {
        items.add(new Item(id,title,state,detail,advanced));
    }
    int count(CheckPolicy.State state) { int n=0; for(Item i:items) if(i.state==state) ++n; return n; }
    boolean allPassed() { return !items.isEmpty() && count(CheckPolicy.State.PASSED)==items.size(); }
    JSONObject json() throws Exception {
        JSONObject out = new JSONObject().put("schema",1).put("request",request).put("createdAt",createdWall)
            .put("mode","test-manual-consent").put("authorizesLaunch",false).put("location",location);
        JSONArray list = new JSONArray();
        for (Item item : items) list.put(new JSONObject().put("id",item.id).put("title",item.title)
            .put("state",item.state.name()).put("detail",item.detail).put("advanced",item.advanced));
        return out.put("checks",list);
    }
}
