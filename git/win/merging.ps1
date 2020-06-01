[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $TargetBranch
)

$MERGE_TO_TARGET="master"

if (!$TargetBranch) {
  Write-Output "No target branch!"
  exit 1
}

if ("$TargetBranch" -eq "$MERGE_TO_TARGET") {
  Write-Output "Target can not same with '$MERGE_TO_TARGET'"
  exit 2
}

MERGE_FROM_CHECKOUT="origin/$TARGET_BRANCH"
MERGE_FROM="merging-$TARGET_BRANCH"

MERGE_TO_CHECKOUT="origin/$MERGE_TO_TARGET"
MERGE_TO="merging-$MERGE_TO_TARGET"

git branch -D $MERGE_FROM $MERGE_TO
git fetch
git checkout -b $MERGE_FROM $MERGE_FROM_CHECKOUT
git checkout -b $MERGE_TO $MERGE_TO_CHECKOUT
git merge $MERGE_FROM -m "Merge branch '$TARGET_BRANCH' into '$MERGE_TO_TARGET'"

Write-Output "$TARGET_BRANCH $MERGE_TO_TARGET $MERGE_FROM_CHECKOUT $MERGE_FROM $MERGE_TO_CHECKOUT $MERGE_TO" > .merging