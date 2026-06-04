#include "game_tower_library_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

int int_from_dict(const Dictionary& dict, const String& key, int fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<int>(static_cast<int64_t>(value));
    }
    return fallback;
}

String string_from_dict(const Dictionary& dict, const String& key, const String& fallback) {
    return String(dict.get(key, fallback));
}

String upper(const String& value) {
    return value.to_upper();
}

Dictionary tower_config_raw(const String& tower_type) {
    Dictionary cfg;
    if (tower_type == "cryo_probe") {
        cfg["label"] = "Cryo Probe";
        cfg["damage"] = 6.0;
        cfg["rate"] = 0.62;
        cfg["range"] = 245.0;
        cfg["color"] = Color(0.34, 0.86, 1.0);
    } else if (tower_type == "bio_lab") {
        cfg["label"] = "Bio-Lab Station";
        cfg["damage"] = 12.0;
        cfg["rate"] = 0.60;
        cfg["range"] = 260.0;
        cfg["color"] = Color(0.46, 1.0, 0.52);
    } else if (tower_type == "magnetic_net") {
        cfg["label"] = "Magnetic Net";
        cfg["damage"] = 5.0;
        cfg["rate"] = 0.48;
        cfg["range"] = 285.0;
        cfg["color"] = Color(0.76, 0.62, 1.0);
    } else if (tower_type == "helios_cannon") {
        cfg["label"] = "Helios Cannon";
        cfg["damage"] = 84.0;
        cfg["rate"] = 0.16;
        cfg["range"] = 305.0;
        cfg["color"] = Color(1.0, 0.43, 0.22);
    } else if (tower_type == "tardigrade_bomb") {
        cfg["label"] = "Tardigrade Bomb";
        cfg["damage"] = 24.0;
        cfg["rate"] = 0.42;
        cfg["range"] = 260.0;
        cfg["color"] = Color(1.0, 0.58, 0.76);
    } else {
        cfg["label"] = "Photon Splitter";
        cfg["damage"] = 17.0;
        cfg["rate"] = 0.95;
        cfg["range"] = 235.0;
        cfg["color"] = Color(1.0, 0.86, 0.28);
    }
    return cfg;
}

Dictionary tower_info_raw(const String& tower_type) {
    Dictionary info;
    if (tower_type == "cryo_probe") {
        info["role"] = "CONTROL  |  SLOW FIELD";
        info["body"] = "Low damage, but every hit chills targets and cuts their speed for a short window.";
        info["note"] = "Can be forced offline by solar storm events.";
    } else if (tower_type == "bio_lab") {
        info["role"] = "SUPPORT  |  EXCAVATION";
        info["body"] = "Analyzes weak points, clears Coronal Burrowers, and can crack Prime's shell.";
        info["note"] = "Research surge events can temporarily multiply Bio-Lab fire rate.";
    } else if (tower_type == "magnetic_net") {
        info["role"] = "CONTROL  |  LONG RANGE";
        info["body"] = "Wide reach and slow effects make it strong at keeping enemies inside kill zones.";
        info["note"] = "Pair with high-damage towers to capitalize on slowed targets.";
    } else if (tower_type == "helios_cannon") {
        info["role"] = "BURST  |  HEAVY ORDNANCE";
        info["body"] = "Slow-firing cannon with high impact damage and excellent range.";
        info["note"] = "Caution: Solar Farmers absorb Helios fire and accelerate.";
    } else if (tower_type == "tardigrade_bomb") {
        info["role"] = "HEAVY SHOT  |  FINISHER";
        info["body"] = "Delivers chunky damage at a measured pace for tougher enemies that survive the net.";
        info["note"] = "Best after Cryo or Magnetic Net has slowed the lane.";
    } else {
        info["role"] = "STEADY BEAM  |  EARLY INTERCEPT";
        info["body"] = "Fast, reliable single-target damage for thinning the first Astrophage lines.";
        info["note"] = "Caution: Photon Mimics ignore it and Solar Farmers feed on photon fire.";
    }
    return info;
}

double number_from_dict(const Dictionary& dict, const String& key, double fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<double>(value);
    }
    return fallback;
}

}

void GameTowerLibraryNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("tower_order"), &GameTowerLibraryNative::tower_order);
    ClassDB::bind_method(D_METHOD("max_level"), &GameTowerLibraryNative::max_level);
    ClassDB::bind_method(D_METHOD("config", "tower_type"), &GameTowerLibraryNative::config);
    ClassDB::bind_method(D_METHOD("info", "tower_type"), &GameTowerLibraryNative::info);
    ClassDB::bind_method(D_METHOD("level", "tower"), &GameTowerLibraryNative::level);
    ClassDB::bind_method(D_METHOD("stats_for_level", "tower_type", "tower_level"), &GameTowerLibraryNative::stats_for_level);
    ClassDB::bind_method(D_METHOD("runtime_stats", "tower"), &GameTowerLibraryNative::runtime_stats);
    ClassDB::bind_method(D_METHOD("tower_cost", "tower_type"), &GameTowerLibraryNative::tower_cost);
    ClassDB::bind_method(D_METHOD("upgrade_cost", "tower"), &GameTowerLibraryNative::upgrade_cost);
    ClassDB::bind_method(D_METHOD("total_spent", "tower"), &GameTowerLibraryNative::total_spent);
    ClassDB::bind_method(D_METHOD("sell_refund", "tower"), &GameTowerLibraryNative::sell_refund);
    ClassDB::bind_method(D_METHOD("short_label", "tower_type"), &GameTowerLibraryNative::short_label);
    ClassDB::bind_method(D_METHOD("selected_readout", "tower_type", "live_build"), &GameTowerLibraryNative::selected_readout);
    ClassDB::bind_method(D_METHOD("managed_view_data", "tower", "rings", "sol_credits"), &GameTowerLibraryNative::managed_view_data);
    ClassDB::bind_method(D_METHOD("button_view_data", "selected_tower", "can_build", "tower_textures", "sol_credits"), &GameTowerLibraryNative::button_view_data);
}

Array GameTowerLibraryNative::tower_order() const {
    Array order;
    order.append("photon_splitter");
    order.append("cryo_probe");
    order.append("bio_lab");
    order.append("magnetic_net");
    order.append("helios_cannon");
    order.append("tardigrade_bomb");
    return order;
}

Dictionary GameTowerLibraryNative::config(const String& tower_type) const {
    return tower_config_raw(tower_type);
}

Dictionary GameTowerLibraryNative::info(const String& tower_type) const {
    return tower_info_raw(tower_type);
}

int GameTowerLibraryNative::level(const Dictionary& tower) const {
    return std::max(1, std::min(MAX_LEVEL, int_from_dict(tower, "level", 1)));
}

Dictionary GameTowerLibraryNative::stats_for_level(const String& tower_type, int tower_level) const {
    Dictionary cfg = config(tower_type);
    const int clamped_level = std::max(1, std::min(MAX_LEVEL, tower_level));
    const double step = static_cast<double>(clamped_level - 1);
    Dictionary stats;
    stats["label"] = cfg["label"];
    stats["damage"] = number_from_dict(cfg, "damage", 0.0) * (1.0 + DAMAGE_LEVEL_BONUS * step);
    stats["rate"] = number_from_dict(cfg, "rate", 0.0) * (1.0 + RATE_LEVEL_BONUS * step);
    stats["range"] = number_from_dict(cfg, "range", 0.0) * (1.0 + RANGE_LEVEL_BONUS * step);
    stats["color"] = cfg["color"];
    return stats;
}

Dictionary GameTowerLibraryNative::runtime_stats(const Dictionary& tower) const {
    return stats_for_level(string_from_dict(tower, "type", "photon_splitter"), level(tower));
}

int GameTowerLibraryNative::tower_cost(const String& tower_type) const {
    if (tower_type == "cryo_probe") return 32;
    if (tower_type == "bio_lab") return 48;
    if (tower_type == "magnetic_net") return 44;
    if (tower_type == "helios_cannon") return 78;
    if (tower_type == "tardigrade_bomb") return 68;
    if (tower_type == "photon_splitter") return 25;
    return 30;
}

int GameTowerLibraryNative::upgrade_cost(const Dictionary& tower) const {
    const int tower_level = level(tower);
    if (tower_level >= MAX_LEVEL) {
        return 0;
    }
    const String tower_type = string_from_dict(tower, "type", "photon_splitter");
    int base_cost = 35;
    if (tower_type == "cryo_probe") base_cost = 42;
    else if (tower_type == "bio_lab") base_cost = 65;
    else if (tower_type == "magnetic_net") base_cost = 58;
    else if (tower_type == "helios_cannon") base_cost = 105;
    else if (tower_type == "tardigrade_bomb") base_cost = 92;
    return static_cast<int>(std::round(static_cast<double>(base_cost) * std::pow(1.45, static_cast<double>(tower_level - 1))));
}

int GameTowerLibraryNative::total_spent(const Dictionary& tower) const {
    return int_from_dict(tower, "spent", tower_cost(string_from_dict(tower, "type", "photon_splitter")));
}

int GameTowerLibraryNative::sell_refund(const Dictionary& tower) const {
    return std::max(1, static_cast<int>(std::round(static_cast<double>(total_spent(tower)) * SELL_REFUND_RATIO)));
}

String GameTowerLibraryNative::short_label(const String& tower_type) const {
    if (tower_type == "photon_splitter") return "PHOTON";
    if (tower_type == "cryo_probe") return "CRYO";
    if (tower_type == "bio_lab") return "BIO-LAB";
    if (tower_type == "magnetic_net") return "MAG NET";
    if (tower_type == "helios_cannon") return "HELIOS";
    if (tower_type == "tardigrade_bomb") return "TARDI";
    return upper(String(config(tower_type).get("label", tower_type)));
}

String GameTowerLibraryNative::selected_readout(const String& tower_type, bool live_build) const {
    const String label = upper(String(config(tower_type).get("label", tower_type)));
    const int cost = tower_cost(tower_type);
    if (live_build) {
        return vformat("LIVE BUILD  |  %s  |  %d SOL", label, cost);
    }
    return vformat("%s READY  |  %d SOL", label, cost);
}

Dictionary GameTowerLibraryNative::managed_view_data(const Dictionary& tower, const Array& rings, int sol_credits) const {
    const String tower_type = string_from_dict(tower, "type", "photon_splitter");
    const Dictionary cfg = config(tower_type);
    const int tower_level = level(tower);
    const Dictionary current_stats = stats_for_level(tower_type, tower_level);
    const Dictionary next_stats = stats_for_level(tower_type, std::min(MAX_LEVEL, tower_level + 1));
    const int next_cost = upgrade_cost(tower);
    const int refund = sell_refund(tower);
    const bool can_upgrade = tower_level < MAX_LEVEL;
    const bool can_afford = next_cost <= 0 || sol_credits >= next_cost;
    String upgrade_cost_text = "MAX";
    String upgrade_button_text = "MAX\nLEVEL";
    if (can_upgrade) {
        upgrade_cost_text = vformat("%d SOL", next_cost);
        upgrade_button_text = vformat("UPGRADE\n%d SOL", next_cost);
        if (!can_afford) {
            upgrade_button_text = vformat("NEED\n%d SOL", next_cost);
        }
    }

    String stats_text = vformat("DMG %.0f  |  RATE %.2f/S  |  RANGE %.0f", current_stats["damage"], current_stats["rate"], current_stats["range"]);
    if (tower_type == "helios_cannon" && tower_level >= 2) {
        stats_text += "\nRIGHT-CLICK TOWER  |  SLINGSHOT SHOT 50 SOL";
    }
    if (can_upgrade) {
        stats_text += vformat("\nNEXT  DMG +%.0f  |  RATE +%.2f/S  |  RANGE +%.0f",
            static_cast<double>(next_stats["damage"]) - static_cast<double>(current_stats["damage"]),
            static_cast<double>(next_stats["rate"]) - static_cast<double>(current_stats["rate"]),
            static_cast<double>(next_stats["range"]) - static_cast<double>(current_stats["range"]));
        stats_text += vformat("\nAFTER %.0f  |  %.2f/S  |  %.0f", next_stats["damage"], next_stats["rate"], next_stats["range"]);
    }

    const int ring_index = int_from_dict(tower, "ring", 0);
    Dictionary ring = rings[ring_index];
    Dictionary data;
    data["title"] = String(cfg["label"]);
    data["meta"] = vformat("R%d %s  |  SLOT %d  |  LEVEL %d/%d", ring_index + 1, upper(String(ring.get("name", ""))), int_from_dict(tower, "slot", 0) + 1, tower_level, MAX_LEVEL);
    data["stats"] = stats_text;
    data["economy"] = vformat("UPGRADE %s  |  SELL REFUND +%d SOL", upgrade_cost_text, refund);
    data["upgrade_text"] = upgrade_button_text;
    data["sell_text"] = vformat("SELL\n+%d SOL", refund);
    data["upgrade_disabled"] = !can_upgrade || !can_afford;
    data["sell_disabled"] = false;
    data["ring_index"] = ring_index;
    data["slot_index"] = int_from_dict(tower, "slot", 0);
    data["accent"] = cfg["color"];
    return data;
}

Dictionary GameTowerLibraryNative::button_view_data(const String& selected_tower, bool can_build, const Dictionary& tower_textures, int sol_credits) const {
    Dictionary button_states;
    const Array order = tower_order();
    for (int i = 0; i < order.size(); ++i) {
        const String tower_type = String(order[i]);
        const int cost = tower_cost(tower_type);
        const Dictionary cfg = config(tower_type);
        const Dictionary tower_info = info(tower_type);
        Dictionary info_data;
        info_data["title"] = upper(String(cfg["label"]));
        info_data["role"] = vformat("KEY %d  |  %s  |  %d SOL", i + 1, tower_info["role"], cost);
        info_data["stats"] = vformat("DAMAGE %.0f  |  RATE %.2f/S  |  RANGE %.0f", cfg["damage"], cfg["rate"], cfg["range"]);
        info_data["body"] = tower_info["body"];
        info_data["note"] = tower_info["note"];
        info_data["accent"] = cfg["color"];

        Dictionary state;
        state["text"] = vformat("%d  %s\n%d SOL", i + 1, short_label(tower_type), cost);
        state["info"] = info_data;
        state["pressed"] = tower_type == selected_tower;
        state["disabled"] = !can_build || sol_credits < cost;
        state["icon"] = tower_textures.get(tower_type, Variant());
        button_states[tower_type] = state;
    }
    return button_states;
}
