#!/bin/bash

echo "flags:"
for DD in `gnustep-config --objc-flags`;do
  echo "  $DD"
done

echo ""
echo "libs:"
for DD in `gnustep-config --objc-libs`;do
  echo "  $DD"
done
