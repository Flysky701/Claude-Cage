package io.github.flysky701.cage.open;

import io.github.flysky701.cage.open.CheckPolicy.State;

public final class CheckPolicyTest {
    public static void main(String[] args) {
        int checked = 0;
        for (State permissions : State.values()) {
            for (State vpn : State.values()) {
                boolean expected = permissions == State.PASSED && vpn == State.PASSED;
                if (CheckPolicy.allowsLaunch(permissions, vpn) != expected) {
                    throw new AssertionError("permissions=" + permissions + ", vpn=" + vpn);
                }
                checked++;
            }
        }
        System.out.println(checked + " CheckPolicy cases passed");
    }
}
