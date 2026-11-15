package io.github.leexeo.cage.shell;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Color;

/** Native translation of ui/src/appearance-presets.mjs (Codex light/dark). */
final class CageTheme {
    final boolean dark;
    final int paper, chrome, ink, muted, line, accent, button, buttonInk, success, danger, warning;
    CageTheme(Context context) {
        String mode=context.getSharedPreferences("cage-android-ui",0).getString("appearance","system");
        dark="dark".equals(mode) || "system".equals(mode) &&
            (context.getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)==Configuration.UI_MODE_NIGHT_YES;
        paper=color(dark?"#181818":"#FFFFFF"); ink=color(dark?"#FFFFFF":"#1A1C1F");
        // Same default contrast mix as the desktop palette; secondary copy remains legible.
        chrome=color(dark?"#252525":"#F4F4F4"); line=color(dark?"#3F3F3F":"#DDDDDE");
        muted=color(dark?"#B2B2B2":"#737373"); accent=color("#339CFF");
        button=ink;buttonInk=paper;success=color(dark?"#70BF56":"#357C3C");
        danger=color(dark?"#F26D78":"#BB3535");warning=color(dark?"#E6B450":"#946719");
    }
    private static int color(String value){return Color.parseColor(value);}
}
