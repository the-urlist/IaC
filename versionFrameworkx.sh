


updateVersion() {
    echo "running updateVersion()"
    echo "latestVersion: $1"
    echo "source file: $2"
}



allFunctions="$(declare -F)"
latestVersion="$(echo $allFunctions | grep -oP "\d_Up" | wc -l)"
sourceFile="$(basename "$0")"

updateVersion $latestVersion $sourceFile