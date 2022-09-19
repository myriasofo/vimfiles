
" Expected format for file
    " $ text to display
    " ( comment

    " % file link (eg. 'linkName: filePath')
    " : use to split linkName vs filePath
    " & for filePath, use a vim varaible for path (eg. &g:dirNotes/dilig.to)

    " # name of workspace 
    " = end of workspace
    " @ command to execute

" Core
    let s:CHAR_DISPLAY_TEXT = '$'
    let s:CHAR_COMMENT = '('

    let s:CHAR_FILELINK = '%'
    let s:CHAR_FILELINK_SPLIT = ':'
    let s:CHAR_FILELINK_VAR = '&'

    let s:CHAR_WORKSPACE = '#'
    let s:CHAR_WORKSPACE_END = '='
    let s:CHAR_COMMAND = '@'


    fun! g:Spacework_Dialog()
        let [arr_displayText, hash_wsFiles] = s:processConfig()
        call s:print_dialog(arr_displayText, hash_wsFiles)
    endfun

    fun! g:Spacework#ExtractConfig()
        " TODO: Refactor everything to use this
        let [l:arr, l:unused] = s:processConfig()

        let l:fileDicts = []
        for l:rawLine in l:arr
            let l:line = StripWhitespace(l:rawLine)
            let l:firstChar = l:line[0]
            if l:firstChar == s:CHAR_FILELINK
                let l:splitLine = SplitOnce(l:line[1:], s:CHAR_FILELINK_SPLIT)

                let l:displayText = StripWhitespace(l:splitLine[0])
                let l:filePath = StripWhitespace(l:splitLine[1])

                let l:fileDict = {'displayText': l:displayText, 'filePath': l:filePath}
                call add(l:fileDicts, l:fileDict)
            endif
        endfor

        return {
            \'files': l:fileDicts,
        \}
    endfun

    fun! s:processConfig()
        let config = s:getConfig()
        let i = 0
        let hash_wsFiles = {}
        let arr_displayText = []

        while i < len(config)
            let lineTrimmed = s:trimLine(config[i])
            let firstChar = lineTrimmed[0]

            if firstChar == s:CHAR_WORKSPACE
                let wsName = lineTrimmed
                call add(arr_displayText, wsName)

                " grab all until '='
                let hash_wsFiles[wsName] = []
                let i = s:process_workspace(config, i+1, hash_wsFiles[wsName])
            elseif firstChar != s:CHAR_COMMENT && firstChar != s:CHAR_WORKSPACE_END
                call add(arr_displayText, lineTrimmed)
            endif

            let i += 1
        endwhile
        return [arr_displayText, hash_wsFiles]
    endfun

    fun! s:process_workspace(config, iStart, wsList)
        " Grab everything for this workspace, until end (ie. '===')
        let i = a:iStart
        while i < len(a:config)
            let lineTrimmed = s:trimLine(a:config[i])

            if lineTrimmed[0] == s:CHAR_WORKSPACE_END
                return i - 1
            elseif lineTrimmed[0] != s:CHAR_COMMENT
                call add(a:wsList, lineTrimmed)
            endif

            let i += 1
        endwhile
        return i
    endfun

    fun! s:print_dialog(arr_displayText, hash_wsFiles)
        set nomore

        let returnCode = 1
        while returnCode
            let jumpList = s:printConfig_topLevel(a:arr_displayText, a:hash_wsFiles)
            let returnCode = s:get_input(a:hash_wsFiles, jumpList)
        endwhile

        set more
        redraw
        return 
    endfun

    fun! s:printConfig_topLevel(arr_displayText, hash_wsFiles)
        echo repeat("\n", 2)

        let jumpList = {}
        call s:reset_jumpKey()
        let maxStr = s:findMaxStrLen(keys(a:hash_wsFiles), 0)

        let printLine = ''
        for l:line in a:arr_displayText
            "echo line
            let line = StripWhitespace(l:line)
            let firstChar = line[0]
            if firstChar == s:CHAR_DISPLAY_TEXT
                let printLine = line[2:] . "\n"
            elseif firstChar == s:CHAR_COMMAND || firstChar == s:CHAR_WORKSPACE || firstChar == s:CHAR_FILELINK
                " TODO: could turn below into a sep fctn. Returns what to echo
                let jumpKey = s:getNext_jumpKey()
                let jumpList[jumpKey] = line

                if firstChar == s:CHAR_COMMAND
                    let printLine = jumpKey . ': ' . line[2:]
                elseif firstChar == s:CHAR_WORKSPACE
                    let wsSize = s:getWsSize(a:hash_wsFiles[line])
                    let filler = repeat(' ', maxStr - strlen(line[2:]))
                    let printLine = jumpKey . ': ' . line[2:] . filler. ' ('.wsSize.')'
                elseif firstChar == s:CHAR_FILELINK
                    "TODO: print properly
                    let splitLine = split(line, ': ')
                    let printLine = jumpKey . ': ' . splitLine[0][2:]
                endif
            else
                let printLine = line . "\n"
            endif
            echo '  ' . printLine
        endfor
        echo ''
        return jumpList
    endfun

    fun! s:get_input(hash_wsFiles, jumpList)
        while 1
            let char = ProcessChar()

            if has_key(a:jumpList, char)
                let cmd = a:jumpList[char]
                let firstChar = cmd[0]
                if firstChar == s:CHAR_COMMAND
                    if cmd == s:CHAR_COMMAND . " openConfig"
                        call OpenFile(g:Spacework_configLocation)
                    elseif cmd == s:CHAR_COMMAND . " addFile"
                        call s:addCurrentFileToConfig(s:CHAR_WORKSPACE . ' [palette')
                    endif
                    return 0
                elseif firstChar == s:CHAR_WORKSPACE
                    "echo '  ' . char
                    return s:pick_wsFile(a:hash_wsFiles[cmd])
                elseif firstChar == s:CHAR_FILELINK
                    "echo 'time to open file'
                    let splitLine = split(cmd, s:CHAR_FILELINK_SPLIT)
                    let l:filename = StripWhitespace(splitLine[1])
                    call OpenFile(l:filename)
                    return 0
                endif
            elseif char == "\<esc>"
                return 0
            else
                echo '  ERROR: "'.char.'" is not a key. Press <esc> or try again: '
            endif

        endwhile
    endfun

    fun! s:pick_wsFile(wsFiles)
        " TODO: clean me
        let jumpList = {}
        call s:reset_jumpKey()

        echo "\n\n  PICK FILE:"
        let maxStr = s:findMaxStrLen(a:wsFiles, 1)
        for line in a:wsFiles
            if line == ""
                echo "\n"
            elseif line[0] == "*"
                echo '  '.line[1:]
            else
                let jumpKey = s:getNext_jumpKey()
                let jumpList[jumpKey] = line
                let fileTail = fnamemodify(line, ":t")
                let parentFolder = fnamemodify(line, ':h:t')
                let filler = repeat(' ', maxStr - strlen(fileTail))
                echo '  ' . jumpKey . ': ' . fileTail . filler . ' (' . parentFolder . ')'
            endif
        endfor
        echo ""

        while 1
            let char = ProcessChar()

            if has_key(jumpList, char)
                call OpenFile(jumpList[char])

                return 0
            elseif char == "\<esc>"
                return 0
            elseif char == " "
                return 1
            else
                echo '  ERROR: "'.char.'" is not a key. Press <esc> or try again: '
            endif
        endwhile
    endfun

" Add file to config (based on workspace name)
    fun! s:addCurrentFileToConfig(wsName)
        let config = s:getConfig()
        call insert(config, expand('%:p'), s:getInsertionIndex_forWs(config, a:wsName))
        call s:setConfig(config)
    endfun

    fun! s:getInsertionIndex_forWs(config, wsName)
        let i = 0
        while i < len(a:config)
            if a:config[i] == a:wsName
                let i = s:findEnd_ofWs(a:config, i+1)
                break
            endif
            let i +=1
        endwhile
        return i
    endfun

    fun! s:findEnd_ofWs(config, iStart)
        let i = a:iStart
        while i < len(a:config)
            if a:config[i][0:2] == s:CHAR_WORKSPACE_END
                if a:config[i-1][0] == s:CHAR_COMMENT
                    let i -= 1
                endif
                break
            endif
            let i += 1
        endwhile
        return i
    endfun

" Helper fctns
    fun! s:findMaxStrLen(strArr, isPaths)
        let maxStr = 0
        for str in a:strArr
            let len = strlen(a:isPaths ? fnamemodify(str, ':t') : str)
            if len > maxStr
                let maxStr = len
            endif
        endfor
        return maxStr
    endfun

    fun! s:getWsSize(wsList)
        let wsSize = 0
        for line in a:wsList
            if line != ""
                let wsSize += 1
            endif
        endfor
        return wsSize
    endfun

    fun! s:trimLine(rawLine)
        let indCurr = match(a:rawLine, '\S')
        return a:rawLine[(indCurr):]
    endfun

    fun! s:reset_jumpKey()
        let g:NavKey_counter = -1
    endfun
    fun! s:getNext_jumpKey()
        let g:NavKey_counter += 1
        return g:NavKey_jumpKeys[g:NavKey_counter]
    endfun

    fun! s:getConfig()
        try
            return readfile(g:Spacework_configLocation)
        catch
            return []
        endtry
    endfun

    fun! s:setConfig(config)
        "Should unload config *before* writing to it
        if buflisted(g:Spacework_configLocation) 
            exe "bunload " g:Spacework_configLocation
        endif

        call writefile(a:config, g:Spacework_configLocation)
    endfun

" Settings
    let g:Spacework_configLocation = g:dir_notes . '_configs/spacework.to'
    let g:Spacework_jumpKeys = 'abcdefghijklmnopqrstuvwxyz3'

