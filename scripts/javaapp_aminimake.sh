# This one is only used for local compile on developer iphone, do not execute if
# - You don't know what will it does.
# - No OpenJDK installed.

/bin/bash <<'EOF'

set -e

cd JavaApp

shopt -s globstar

mkdir -p local_out/classes
javac -cp "libs/*" -d local_out/classes src/main/java/**/*.java

cd local_out/classes
jar -c -f ../launcher.jar *

cp ../launcher.jar /Applications/PojavLauncher.app/libs/launcher.jar

echo "BUILD SUCCESSFUL"

EOF
