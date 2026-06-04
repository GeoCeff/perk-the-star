#include "register_types.h"
#include "orbital_tower.h"
#include "astrophage.h"
#include "sun_node.h"
#include "wave_data.h"
#include "v2_gameplay_math.h"
#include "game_orbit_math_native.h"
#include "game_effect_store_native.h"
#include "game_view_controller_native.h"
#include "game_sfx_bus_native.h"
#include "game_tower_library_native.h"
#include "game_wave_library_native.h"
#include "main_menu_buttons_native.h"
#include "settings_controls_native.h"
#include "animated_space_background_native.h"
#include "hud_panel_fx_native.h"
#include "main_menu_native.h"
#include "main_menu_fx_native.h"
#include "game_pause_menu_native.h"
#include "settings_overlay_native.h"
#include "tutorial_overlay_native.h"
#include "music_manager_native.h"
#include "codex_native.h"
#include "game_state_native.h"
#include "game_catalog_native.h"
#include "space_theme_native.h"
#include "game_hud_native.h"
#include "game_runtime_native.h"

#include <gdextension_interface.h>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_perk_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    ClassDB::register_class<OrbitalTower>();
    ClassDB::register_class<Astrophage>();
    ClassDB::register_class<SunNode>();
    ClassDB::register_class<WaveData>();
    ClassDB::register_class<V2GameplayMath>();
    ClassDB::register_class<GameOrbitMathNative>();
    ClassDB::register_class<GameEffectStoreNative>();
    ClassDB::register_class<GameViewControllerNative>();
    ClassDB::register_class<GameSfxBusNative>();
    ClassDB::register_class<GameTowerLibraryNative>();
    ClassDB::register_class<GameWaveLibraryNative>();
    ClassDB::register_class<MainMenuPlayButtonNative>();
    ClassDB::register_class<MainMenuCodexButtonNative>();
    ClassDB::register_class<MainMenuSettingsButtonNative>();
    ClassDB::register_class<MainMenuExitButtonNative>();
    ClassDB::register_class<MainMenuMusicToggleNative>();
    ClassDB::register_class<MainMenuMusicVolumeSliderNative>();
    ClassDB::register_class<SettingsOverlayCloseButtonNative>();
    ClassDB::register_class<AnimatedSpaceBackgroundNative>();
    ClassDB::register_class<HudPanelFxNative>();
    ClassDB::register_class<MainMenuNative>();
    ClassDB::register_class<MainMenuFxNative>();
    ClassDB::register_class<GamePauseMenuNative>();
    ClassDB::register_class<SettingsOverlayNative>();
    ClassDB::register_class<TutorialOverlayNative>();
    ClassDB::register_class<MusicManagerNative>();
    ClassDB::register_class<CodexNative>();
    ClassDB::register_class<GameStateNative>();
    ClassDB::register_class<GameCatalogNative>();
    ClassDB::register_class<SpaceThemeNative>();
    ClassDB::register_class<GameHudNative>();
    ClassDB::register_class<GameRuntimeNative>();
}

void uninitialize_perk_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {
GDExtensionBool GDE_EXPORT perk_the_star_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    GDExtensionClassLibraryPtr         p_library,
    GDExtensionInitialization*         r_initialization)
{
    GDExtensionBinding::InitObject init_obj(
        p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_perk_module);
    init_obj.register_terminator(uninitialize_perk_module);
    init_obj.set_minimum_library_initialization_level(
        MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
