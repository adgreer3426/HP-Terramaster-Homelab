-- NAS Transfer Droplet
-- Drop files or folders onto this app to rsync them to the media share.
-- Checks if /Volumes/media is mounted; if not, attempts to mount via SMB.

property nasIP : "192.168.1.25"
property shareName : "media"
property mountPoint : "/Volumes/media"

on open droppedItems
	-- Check if share is mounted; if not, try to mount it
	tell application "Finder"
		if not (exists disk shareName) then
			try
				mount volume ("smb://" & nasIP & "/" & shareName)
				delay 2
			on error errMsg
				display alert "Could not mount NAS share" message "Failed to connect to smb://" & nasIP & "/" & shareName & return & return & errMsg buttons {"Cancel"} default button "Cancel" as critical
				return
			end try
		end if
	end tell

	-- Build list of source paths
	set sourceList to ""
	repeat with anItem in droppedItems
		set itemPath to POSIX path of anItem
		-- Wrap in quotes to handle spaces
		set sourceList to sourceList & quoted form of itemPath & " "
	end repeat

	-- Build rsync command
	-- -r  recursive
	-- -l  preserve symlinks
	-- -t  preserve timestamps
	-- -h  human-readable sizes
	-- -v  verbose
	-- --no-perms --no-owner --no-group  skip Unix permission sync (SMB doesn't support it)
	-- --inplace   write directly to destination file instead of temp-then-rename (required for SMB)
	-- --progress  show per-file progress
	-- --exclude   skip macOS metadata files that cause errors on SMB
	-- Use Homebrew GNU rsync if available (fixes openrsync SMB bugs on macOS Tahoe)
	-- Install with: brew install rsync
	set rsyncBin to "/opt/homebrew/bin/rsync"
	try
		do shell script "test -x " & rsyncBin
	on error
		set rsyncBin to "/usr/bin/rsync"
	end try

	set rsyncCmd to rsyncBin & " -rltvh --no-perms --no-owner --no-group --inplace --progress --exclude='.DS_Store' --exclude='._*' --exclude='.Spotlight-V100' --exclude='.Trashes' " & sourceList & quoted form of mountPoint & "/"

	-- Run in a visible Terminal window so you can watch progress
	tell application "Terminal"
		activate
		set xferWindow to do script rsyncCmd
		-- Wait for rsync to finish, then notify
		repeat
			delay 3
			if not busy of xferWindow then exit repeat
		end repeat
		do script "echo '\\n✅ Transfer complete.'" in xferWindow
	end tell

	display notification "All items transferred to " & shareName & " share." with title "NAS Transfer Complete"
end open

-- When launched without dropping files, show usage instructions
on run
	display alert "NAS Transfer" message "Drop files or folders onto this app to transfer them to the \"" & shareName & "\" share on your NAS (" & nasIP & ") using rsync." buttons {"OK"} default button "OK"
end run
