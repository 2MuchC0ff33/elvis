#!/bin/sh

echo "Checking repository integrity..."
git fsck

echo "Cleaning untracked files and directories..."
git clean -xfd

echo "Cleaning ignored files..."
git clean -Xfd

echo "Expiring reflogs..."
git reflog expire --expire=now --all

echo "Pruning unreachable objects..."
git gc --aggressive --prune=now

echo "Repacking repository aggressively..."
git repack -Ad

echo "Pruning remote tracking branches..."
git remote prune origin

echo "Repository deep cleanup complete!"
