
" WHAT - Menu for quick access to commonly-used files

" KEY
" '$ text to display' 
" '@ command to execute'
" '# name of workspace' 
" === : marks end of workspace

fun! Spacework_Dialog()
    let [arr_displayText, hash_wsFiles] = s:process_cache()
    call s:print_dialog(arr_displayText, hash_wsFiles)
endfun

fun! s:process_cache()
    let cache = s:getCache()
    let i = 0
    let hash_wsFiles = {}
    let arr_displayText = []

    while i < len(cache)
        let lineTrimmed = s:trimLine(cache[i])
        let firstChar = lineTrimmed[0]

        if firstChar == '#'
            let wsName = lineTrimmed
            call add(arr_displayText, wsName)

            " grab all until '==='
            let hash_wsFiles[wsName] = []
            let i = s:process_workspace(cache, i+1, hash_wsFiles[wsName])
        "elseif firstChar == '' || firstChar == '@' || firstChar == "$" || firstChar == "%"
        elseif firstChar != '(' && firstChar != '='
            call add(arr_displayText, lineTrimmed)
        endif

        let i += 1
    endwhile
    return [arr_displayText, hash_wsFiles]
endfun
fun! s:process_workspace(cache, iStart, wsList)
    " Grab everything for this workspace, until end (ie. '===')
    let i = a:iStart
    while i < len(a:cache)
        let lineTrimmed = s:trimLine(a:cache[i])

        if lineTrimmed[0:2] == '==='
            return i - 1
        elseif lineTrimmed[0] != '('
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
        let jumpList = s:printCache_topLevel(a:arr_displayText, a:hash_wsFiles)
        let returnCode = s:get_input(a:arr_displayText, a:hash_wsFiles, jumpList)
    endwhile

    set more
    redraw
    return 
endfun
fun! s:printCache_topLevel(arr_displayText, hash_wsFiles)
    echo repeat("\n", 2)

    let jumpList = {}
    call s:reset_jumpKey()
    let maxStr = s:findMaxStrLen(keys(a:hash_wsFiles), 0)

    let printLine = ''
    for line in a:arr_displayText
        "echo line
        let firstChar = line[0]
        if firstChar == "$"
            let printLine = line[2:] . "\n"
        elseif firstChar == "@" || firstChar == "#" || firstChar == "%"
            " TODO: could turn below into a sep fctn. Returns what to echo
            let jumpKey = s:getNext_jumpKey()
            let jumpList[jumpKey] = line

            if firstChar == "@"
                let printLine = jumpKey . ': ' . line[2:]
            elseif firstChar == "#"
                let wsSize = s:getWsSize(a:hash_wsFiles[line])
                let filler = repeat(' ', maxStr - strlen(line[2:]))
                let printLine = jumpKey . ': ' . line[2:] . filler. ' ('.wsSize.')'
            elseif firstChar == "%"
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
fun! s:get_input(arr_displayText, hash_wsFiles, jumpList)
    while 1
        let char = ProcessChar()

        if has_key(a:jumpList, char)
            let cmd = a:jumpList[char]
            let firstChar = cmd[0]
            if firstChar == "@"
                if cmd == "@ openCache"
                    exe "edit " g:Spacework_cacheLocation
                elseif cmd == "@ addFile"
                    call s:addCurrentFileToCache('# [palette')
                endif
                return 0
            elseif firstChar == "#"
                echo '  ' . char
                return s:pick_wsFile(a:hash_wsFiles[cmd])
            elseif firstChar == "%"
                echo 'time to open file'
                let splitLine = split(cmd, ': ')
                exe "edit " . splitLine[1]
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
            exe "edit " jumpList[char]

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


" Add file to cache (based on workspace name)
    fun! s:addCurrentFileToCache(wsName)
        let cache = s:getCache()
        call insert(cache, expand('%:p'), s:getInsertionIndex_forWs(cache, a:wsName))
        call s:setCache(cache)
    endfun
    fun! s:getInsertionIndex_forWs(cache, wsName)
        let i = 0
        while i < len(a:cache)
            if a:cache[i] == a:wsName
                let i = s:findEnd_ofWs(a:cache, i+1)
                break
            endif
            let i +=1
        endwhile
        return i
    endfun
    fun! s:findEnd_ofWs(cache, iStart)
        let i = a:iStart
        while i < len(a:cache)
            if a:cache[i][0:2] == "==="
                if a:cache[i-1][0] == "("
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


    fun! s:getCache()
        try
            return readfile(g:Spacework_cacheLocation)
        catch
            return []
        endtry
    endfun

    fun! s:setCache(cache)
        "Should unload cache *before* writing to it
        if buflisted(g:Spacework_cacheLocation) 
            exe "MBEbun " g:Spacework_cacheLocation
        endif

        call writefile(a:cache, g:Spacework_cacheLocation)
    endfun


" Settings
let g:Spacework_jumpKeys = 'abcdefghijklmnopqrstuvwxyz3'

