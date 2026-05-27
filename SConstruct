from SCons.Script import ARGUMENTS, Environment, Glob

env = Environment(
    tools=["default"],
)

platform = ARGUMENTS.get("platform", "windows")
target = ARGUMENTS.get("target", "template_debug")
arch = ARGUMENTS.get("arch", "x86_64")

if platform == "windows":
    env.Append(CPPFLAGS=["/std:c++17"])
else:
    env.Append(CPPFLAGS=["-std=c++17"])

godot_cpp_dir = "godot-cpp"

env.Append(CPPPATH=[
    f"{godot_cpp_dir}/include",
    f"{godot_cpp_dir}/gen/include",
    f"{godot_cpp_dir}/godot-headers",
    "gdextension/src",
    "src"
])

env.Append(LIBPATH=[f"{godot_cpp_dir}/bin"])

env.Append(LIBS=[
    f"libgodot-cpp.{platform}.{target}.{arch}"
])

sources = Glob("gdextension/src/*.cpp")

env.SharedLibrary(
    target="game/bin/perk_the_star",
    source=sources
)
