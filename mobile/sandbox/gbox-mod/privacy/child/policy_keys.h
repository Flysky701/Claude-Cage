#pragma once

struct CageProperty { const char* name; const char* value; };
static const struct CageProperty kSimProperties[] = {
    {"gsm.sim.state", "ABSENT"},
    {"gsm.sim.operator.alpha", ""},
    {"gsm.sim.operator.numeric", ""},
    {"gsm.sim.operator.iso-country", ""},
    {"gsm.operator.alpha", ""},
    {"gsm.operator.numeric", ""},
    {"gsm.operator.iso-country", ""},
    {"gsm.operator.isroaming", "false"},
    {"gsm.current.phone-type", "0"}
};
// persist.radio.multisim.config and telephony.active_modems.max_count describe
// device capacity. Neither is intercepted.

