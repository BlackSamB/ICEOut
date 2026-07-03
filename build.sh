#!/bin/bash
# ═══════════════════════════════════════════
# build.sh — Terminal build & deploy for all apps
# Usage: ./build.sh <project> [debug|release|deploy|icon]
# Examples:
#   ./build.sh QuickConvert debug
#   ./build.sh SoundMeter release
#   ./build.sh TrueNorth deploy
#   ./build.sh ICEOut icon "#f59e0b" "#101014" "IO"
# ═══════════════════════════════════════════

set -e

export JAVA_HOME=/usr/lib/jvm/java-17-temurin
export ANDROID_HOME=~/android-sdk
export PATH="$ANDROID_HOME/platform-tools:$PATH"

PROJECT="$1"
ACTION="${2:-debug}"

if [ -z "$PROJECT" ]; then
  echo "Available projects:"
  for d in QuickConvert SoundMeter TrueNorth SomeTrails ICEOut; do
    [ -d "$HOME/$d" ] && echo "  $d"
  done
  echo ""
  echo "Usage: $0 <project> [debug|release|deploy|icon|serve]"
  exit 1
fi

PROJECT_DIR="$HOME/$PROJECT"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR not found"
  exit 1
fi

cd "$PROJECT_DIR"

case "$ACTION" in
  debug)
    echo "==> Building debug APK for $PROJECT..."
    gradle assembleDebug
    APK=$(find app/build/outputs/apk/debug -name "*.apk" | head -1)
    echo "==> Built: $APK"
    echo "==> Size: $(du -sh "$APK" | cut -f1)"
    ;;

  release)
    echo "==> Building release AAB for $PROJECT..."
    if [ ! -f "release-key.jks" ] && [ ! -f "$HOME/release-key.jks" ]; then
      echo "Error: No keystore found. Generate one first:"
      echo "  keytool -genkey -v -keystore ~/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ${PROJECT,,}"
      exit 1
    fi
    gradle bundleRelease
    AAB=$(find app/build/outputs/bundle/release -name "*.aab" | head -1)
    echo "==> Built: $AAB"
    echo "==> Size: $(du -sh "$AAB" | cut -f1)"
    ;;

  deploy)
    echo "==> Building and deploying debug APK for $PROJECT..."
    gradle assembleDebug
    APK=$(find app/build/outputs/apk/debug -name "*.apk" | head -1)
    FNAME="${PROJECT,,}-debug.apk"
    echo "==> Deploying $FNAME to Nextcloud..."
    scp "$APK" npc@10.0.0.172:/tmp/"$FNAME"
    ssh npc@10.0.0.172 "sudo cp /tmp/$FNAME /opt/ncdata/data/ncp/files/ && \
      sudo chown www-data:www-data /opt/ncdata/data/ncp/files/$FNAME && \
      sudo -u www-data php /var/www/nextcloud/occ files:scan ncp"
    echo "==> Deployed! Download from Nextcloud on your phone."
    ;;

  serve)
    echo "==> Serving web app for browser testing..."
    echo "==> Open http://10.0.0.213:8888 on your phone"
    echo "==> Ctrl+C to stop"
    cd app/src/main/assets/web
    python3 -m http.server 8888
    ;;

  icon)
    # Usage: ./build.sh ProjectName icon "#bg" "#fg" "TEXT"
    BG="${3:-#6c5ce7}"
    FG="${4:-white}"
    TEXT="${5:-??}"
    echo "==> Generating icons: bg=$BG fg=$FG text=$TEXT"
    RES="app/src/main/res"
    for spec in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
      NAME="${spec%%:*}"
      SIZE="${spec##*:}"
      DIR="$RES/mipmap-$NAME"
      mkdir -p "$DIR"
      FS=$((SIZE * 45 / 100))
      convert -size "${SIZE}x${SIZE}" "xc:${BG}" \
        -fill "$FG" -font DejaVu-Sans-Bold -pointsize "$FS" \
        -gravity center -annotate +0+0 "$TEXT" \
        "$DIR/ic_launcher.png"
      echo "  $NAME: ${SIZE}x${SIZE}"
    done
    echo "==> Icons generated."
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Actions: debug, release, deploy, serve, icon"
    exit 1
    ;;
esac
