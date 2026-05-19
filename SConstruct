import os
from SCons.Script import Environment, Glob

import os
from SCons.Script import Environment, Glob

env = Environment(
    tools=["default"],
)

env.Append(CPPFLAGS=["/std:c++17"])

godot_cpp_dir = "godot-cpp"

env.Append(CPPPATH=[
    f"{godot_cpp_dir}/include",
    f"{godot_cpp_dir}/gen/include",
    f"{godot_cpp_dir}/godot-headers",
    "src"
])

env.Append(LIBPATH=[f"{godot_cpp_dir}/bin"])

env.Append(LIBS=[
    "libgodot-cpp.windows.template_debug.x86_64"
])

sources = Glob("src/**/*.cpp")

env.SharedLibrary(
    target="game/bin/perk_the_star",
    source=sources
)