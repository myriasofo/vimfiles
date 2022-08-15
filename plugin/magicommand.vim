

" Constants
let g:magiLayoutMode = 2
let s:leftPadding = 4
let s:minimumWidth = 7
let s:glasConfigLocation = g:dir_notes . '_configs/glas.to'
let s:hotkeysToBufPaths = {}
let s:decantFiles = [
    \'1.to',
    \'2.to',
    \]

let s:mapPaletteFiles = {
    \'B.to':       'B',
    \'A.to':       'A',
    \'0.to':       '0',
    \'1.to':       '1',
    \'2.to':       '2',
    \'timeLog.to': 'L',
    \}

let s:ignoredFiles = [
    \'vimrc',
    \'abe_shell',
\]

" Core layouts
function! s:layoutVisibleBufs(bufNums)
    let [l:hiddenBufs, l:visibleBufs] = s:divideBufsIntoHiddenAndVisible(a:bufNums)

    let magiList = []

    call add(magiList, '')
    call s:addBufs(magiList, l:visibleBufs)
    call add(magiList, '')

    " Usually have 2 wins visible. So if only one, then add an extra linebreak
    if len(l:visibleBufs) == 1
        call add(magiList, '')
    endif

    "call s:addGlasBufs(magiList)
    call s:addSpecialBufs(magiList)
    call s:addBufs(magiList, l:hiddenBufs)
    call s:addConflictsFromDropbox(magiList)

    return magiList
endfunction

function! s:layoutGlas(bufNums)
    let [l:special, l:remaining] = s:divideBufsIntoSpecialAndRemaining(a:bufNums)

    let magiList = []

    call add(magiList, '')
    "call add(magiList, '    Special')
    "call s:addSpecialBufs2(magiList)
    call s:addGlasBufs(magiList)

    if magiList[-1] != ''
        call add(magiList, '')
    endif
    call add(magiList, '    # Remaining')
    call s:addSpecialBufs2(magiList)
    call s:addBufs(magiList, l:remaining)
    call s:addConflictsFromDropbox(magiList)

    return magiList
endfunction


" Making lists of bufs
function! s:divideBufsIntoSpecialAndRemaining(bufNums)
    let l:special = []
    let l:remaining = []

    for l:i in a:bufNums
        if s:isSpecialBuf(l:i)
            if IsBufVisible(l:i)
                "call add(l:remaining, l:i)
                continue
            endif
        else
            call add(l:remaining, l:i)
        endif
    endfor

    call sort(l:special, "s:compareName")
    call sort(l:remaining, "s:compareBufName")
    return [l:special, l:remaining]
endfunction

function! s:divideBufsIntoHiddenAndVisible(bufNums)
    let l:hiddenBufs = []
    let l:visibleBufs = []

    for l:i in a:bufNums
        if !IsBufVisible(l:i)
            if !s:isSpecialBuf(l:i)
                call add(l:hiddenBufs, l:i)
            endif
        else
            call add(l:visibleBufs, l:i)
        endif
    endfor

    call sort(l:visibleBufs, "s:compareWinNum")
    call sort(l:hiddenBufs, "s:compareBufName")

    return [l:hiddenBufs, l:visibleBufs]
endfunction

function! s:addGlasBufs(magiList)
    "Add all from current glas palette (global var)
    let l:rawGlasLines = s:getRawGlasLines()
    let l:rootPath = ''
    let l:folderPath = ''
    let l:folderStub = ''

    for l:line in l:rawGlasLines
        let l:firstChar = l:line[0]
        let l:content = StripWhitespace(l:line[1:])

        "Display this text (only)
        if l:firstChar == '$'
            let l:stub = s:getLeftPadding() . l:content
            call add(a:magiList, l:stub)

        "Set root path
        elseif l:firstChar == '@'
            let l:parts = split(l:content, ':')
            let l:rootPath = StripWhitespace(l:parts[1])

        "Set folder
        elseif l:firstChar == '#'
            let l:parts = split(l:content, ':')
            let l:folderDesc = StripWhitespace(l:parts[0])
            let l:rawFolderPath = StripWhitespace(l:parts[1])
            let l:folderStub = s:getLeftPadding() . '# ' . l:folderDesc

            if l:rawFolderPath == '/'
                let l:folderPath = ''
            else
                let l:folderPath = substitute(l:rawFolderPath, '{root}', l:rootPath, '') . '/'
            endif            

        "Add file
        else 
            if l:folderStub != '' "Only show folder if it has files (!)
                if a:magiList[-1] != ''
                    call add(a:magiList, '')
                endif
                call add(a:magiList, l:folderStub)
                let l:folderStub = ''
            endif

            if l:firstChar == '&'
                let l:displayed = l:content
                let l:firstChar = l:content[0]
                let l:line = l:content
            else
                let l:displayed = fnamemodify(l:line, ':t')
            endif

            if l:firstChar == '~'
                let l:path = l:line
            elseif l:firstChar == '/'
                let l:path = l:line
            else
                let l:path = l:folderPath . l:line
            endif

            let l:stub = s:createStub(l:path, l:displayed)
            call add(a:magiList, l:stub)
        endif
    endfor
endfunction

function! s:getRawGlasLines()
    let l:rawGlasLines = []

    let l:skip = 0
    for l:rawLine in s:getGlasConfig()
        let l:line = StripWhitespace(l:rawLine)
        let l:firstChar = l:line[0]
        let l:firstTwoChars = l:line[:1]

        if l:firstChar == '' || l:firstChar == '('
            continue
        endif

        if l:firstTwoChars == '/*'
            let l:skip += 1
            continue
        elseif l:firstTwoChars == '*/'
            let l:skip = l:skip == 0 ? 0 : l:skip - 1 "Handling nested comment blocks
            continue
        elseif l:firstChar == '*' "Allow `*` to start title of section for convenience
            continue
        elseif l:skip > 0
            continue
        endif

        call add(l:rawGlasLines, l:line)
    endfor

    return l:rawGlasLines
endfunction

function! s:addSpecialBufs(magiList)
    for l:tail in s:decantFiles
        let l:path = g:dir_palettes . l:tail
        if IsBufVisible(l:path)
            continue
        endif

        let firstThreeLines = s:getFileLines(l:path, 3) "If files are empty, they'll have exactly 2 lines
        if len(firstThreeLines) > 2
            call add(a:magiList, s:createStub(l:path, l:tail))
        endif
    endfor
endfunction

function! s:addSpecialBufs2(magiList)
    " version 1
    "for tail in special
    "  let path = fnamemodify(g:dir_palettes . tail, ':p')
    "  call add(a:magiList, s:createStub(path, tail))
    "endfor


    " version 2
    " Hard to tell what's going on
    "for tail in special
    "  let path = fnamemodify(g:dir_palettes . tail, ':p')
    "
    "  if IsBufVisible(path)
    "    call add(a:magiList, s:createStub(path, tail))
    "  elseif has_key(tempFiles, tail)
    "    let firstThreeLines = s:getFileLines(l:path, 3) "If files are empty, they'll have exactly 2 lines
    "    if len(firstThreeLines) > 2
    "      call add(a:magiList, s:createStub(path, tail))
    "    endif
    "  endif
    "endfor

    " version 3
    " Minimal. Might be all I need
    for tail in s:decantFiles
        let path = fnamemodify(g:dir_palettes . tail, ':p')
        if IsBufVisible(path)
            continue
        endif

        let firstThreeLines = s:getFileLines(l:path, 3) "If files are empty, they'll have exactly 2 lines
        if len(firstThreeLines) > 2
            call add(a:magiList, s:createStub(path, tail))
        endif
    endfor
endfunction

function! s:addBufs(magiList, bufNums)
    for l:i in a:bufNums
        let l:filename = expand('#'.l:i.':p')
        if !has_key(s:loadedBufs, l:filename)
            call add(a:magiList, s:createStubFromBufNum(l:i))
        endif
    endfor
endfunction

function! s:addConflictsFromDropbox(magiList)
    let l:note_files = split(globpath(g:dir_notes, '**'), '\n')

    for l:file in l:note_files
        if match(l:file, 'conflicted copy') >= 0
            let l:displayed = fnamemodify(l:file, ':t')
            let l:stub = s:createStub(l:file, l:displayed)
            call add(a:magiList, l:stub)
        endif
    endfor
endfunction

function! s:compareWinNum(bufNum1, bufNum2)
    let l:win1 = bufwinnr(a:bufNum1)
    let l:win2 = bufwinnr(a:bufNum2)

    return l:win1 - l:win2
endfunction

function! s:compareBufName(bufNum1, bufNum2)
    let l:bufName1 = expand("#".a:bufNum1.":p:t")
    let l:bufName2 = expand("#".a:bufNum2.":p:t")

    if l:bufName1 < l:bufName2
        return -1
    elseif l:bufName1 > l:bufName2
        return 1
    else
        return 0
    endif
endfunction

function! s:populateIgnoredFiles()
    for l:fileTail in keys(s:mapPaletteFiles)
        call add(s:ignoredFiles, l:fileTail)
    endfor

    for l:fileDict in g:Spacework#ExtractConfig()['files']
        let l:filePath = l:fileDict['filePath']
        let l:fileTail = fnamemodify(l:filePath, ':t')
        call add(s:ignoredFiles, l:fileTail)
    endfor
endfunction


" Creating stub (each formatted line in magi)
function! s:createStub(path, fileDesc)
    let l:path = fnamemodify(a:path, ':p')
    let l:path = substitute(l:path, '//', '/', 'g') "NOTE: If two slashes, combine into one

    let l:fileDesc = a:fileDesc
    if has_key(s:mapPaletteFiles, a:fileDesc)
        let l:fileDesc = s:mapPaletteFiles[a:fileDesc]
    endif

    let l:stub = ''
    let l:stub .= s:getStubMargin(l:path)
    let l:stub .= l:fileDesc
    let l:stub .= s:isBufModified(l:path) ? '+' : ' '
  
    let s:loadedBufs[l:path] = 1
    return l:stub
endfunction

function! s:createStubFromBufNum(bufNum)
    let l:fileDesc = s:bufUniqNameDict[a:bufNum]

    " for terminals
    let FILE_NO_NAME = '--NO NAME--'
    let lenNoName = len(FILE_NO_NAME) - 1
    if l:fileDesc[:lenNoName] == FILE_NO_NAME
        if getbufvar(a:bufNum, "&buftype") == 'terminal'
            let shell_name = fnamemodify(&shell, ':t')
            let l:fileDesc = shell_name . '-'
        elseif getbufvar(a:bufNum, "&buftype") == 'quickfix'
            let l:fileDesc = '(quickfix)'
        endif
    endif

    let l:path = expand('#' . a:bufNum . ':p')
    return s:createStub(l:path, l:fileDesc)
endfunction

function! s:getLeftPadding(...)
    "echom 'args' . a:0
    let l:paddingAdjust = a:0 > 0 ? a:1 : 0
    let l:padding = repeat(' ', s:leftPadding + l:paddingAdjust)
    return l:padding
endfunction

function! s:getFileLines(path, nLines)
    if bufloaded(a:path)
        return getbufline(a:path, 0, a:nLines)
    else
        silent! let lines = readfile(a:path, 0, a:nLines)
        return lines
    endif
endfunction

function! s:getMagiHotkey(path)
    " char "a" is 97 and "z" is 122
    let letter = nr2char(97 + len(s:hotkeysToBufPaths))
    let s:hotkeysToBufPaths[letter] = fnameescape(a:path)
    return letter
endfunction

function! s:getMagiMarker(path)
    if a:path == fnamemodify(bufname('%'), ':p')
        if g:magiLayoutMode == 1
            return '*'
        else
            return '***'
        endif

    elseif IsBufVisible(a:path)
        if g:magiLayoutMode == 1
            return ''
        else
            return '---'
        endif

    elseif s:isSpecialBuf(a:path)
        let l:tail = fnamemodify(a:path, ':t')
        if s:hasElement(s:decantFiles, l:tail)
            let firstThreeLines = s:getFileLines(a:path, 3) "If files are empty, they'll have exactly 2 lines
            if len(firstThreeLines) > 2
                return '~'
            endif
        endif
        return s:getLeftPadding()

    else
        return s:getMagiHotkey(a:path) . ' '
    endif
endfunction

function! s:hasElement(myList, elem)
    return index(a:myList, a:elem) != -1
endfunction

function! s:getStubMargin(path)
    let l:marker = s:getMagiMarker(a:path)
    let l:padding = s:getLeftPadding(strlen(l:marker) * -1)
    return l:padding . l:marker
endfunction

function! s:isBufModified(path)
    let shell_name = fnamemodify(&shell, ':t')
    if fnamemodify(a:path, ':t')[:len(shell_name)-1] == shell_name
        return 0
    end

    return bufloaded(a:path) && getbufvar(bufnr(a:path), '&modified')
endfunction

function! s:getGlasConfig()
    try
        return readfile(s:glasConfigLocation)
    catch
        return []
    endtry
endfunction

function! s:saveGlasConfig(config)
    if buflisted(s:glasConfigLocation) 
        exe "bunload " s:glasConfigLocation
    endif

    call writefile(a:config, s:glasConfigLocation)
endfunction

function! s:isSpecialBuf(bufNum)
    if type(a:bufNum) == 0
        let path = expand('#'.a:bufNum.':p')
    else
        let path = a:bufNum
    endif

    return (
        \s:hasElement(s:ignoredFiles, fnamemodify(path, ':t'))
        \|| isdirectory(bufname(a:bufNum))
    \)
endfunction


" External API
function! MagiOpenBuffer(key)
    if has_key(s:hotkeysToBufPaths, a:key)
        let filePath = s:hotkeysToBufPaths[a:key]
        let currentFilePath = expand('%')

        if filePath != currentFilePath
            exe 'e ' . filePath
            return
        endif
    endif

    echom "ERROR: No such key for buffer"
endfun

function! MagiRemoveBuffer(key)
    if has_key(s:hotkeysToBufPaths, a:key)
        let filePath = s:hotkeysToBufPaths[a:key]
        exe 'bwipeout ' . filePath
        return
    endif

    echom "ERROR: No such key for buffer"
endfun

function! MagiGetViewerList(bufNums, bufUniqNameDict)
    let s:bufUniqNameDict = a:bufUniqNameDict
    let s:hotkeysToBufPaths = {}
    let s:loadedBufs = {}

    if !exists('s:populatedIgnoredFiles')
        let s:populatedIgnoredFiles = 1
        call s:populateIgnoredFiles()
    endif

    if g:magiLayoutMode == 1
        return s:layoutVisibleBufs(a:bufNums)
    else
        return s:layoutGlas(a:bufNums)
    endif
endfunction

function! MagiDetermineViewerWidth(magiList)
    let l:magiWidth = s:minimumWidth

    for l:line in a:magiList
        if strlen(l:line) > l:magiWidth
            let l:magiWidth = strlen(l:line)
        endif
    endfor

    return l:magiWidth
endfunction

function! IsMagiOpen()
    return getwinvar(1, '&filetype') == 'minibufexpl'
    "return (bufname(winbufnr(1)) == "-MiniBufExplorer-")
    " alt: could check each win and see if any are
    "for i in winnr('$')
endfun


" User Commands
function! s:refreshMagi()
    if IsMagiOpen() == 0
        return
    endif

    " Switch to diff window to trigger refresh
    let currentWin = bufwinnr('%')
    let diffWin = currentWin == 1 ? 2 : 1
    exe diffWin    . ' wincmd w'
    exe currentWin . ' wincmd w'
endfun

function! s:glasToggle()
    let g:magiLayoutMode = g:magiLayoutMode == 1 ? 2 : 1
    call s:refreshMagi()
endfun

function! s:glasClear(nStart, nEnd)
    " WHAT - comment out all lines that are files

    let skippedChars = [
        \'\',
        \'*',
        \'(',
        \'|',
        \'@',
        \'#',
        \]
        "\'$',

    for i in range(a:nStart, a:nEnd)
        let rawLine = getline(i)
        let line = StripWhitespace(rawLine)
        if len(line) == 0
            continue
        endif

        if s:hasElement(skippedChars, line[0])
            continue
        endif

        call tcomment#Comment(i, i)
    endfor

    write
    MagiRefresh
endfunction

function! s:glasAddFile()
    let config = s:getGlasConfig()
    let currentFilePath = expand('%:~')

    call add(config, currentFilePath)

    call s:saveGlasConfig(config)

    call s:refreshMagi()
endfunction


command! MagiRefresh call s:refreshMagi()
command! GlasToggle call s:glasToggle()
command! GlasAddFile call s:glasAddFile()
command! ToggleGlas call s:glasToggle()
command! -range=% GlasClear call s:glasClear(<line1>, <line2>)

" Settings for MBE (this should be deprecated)
    let g:miniBufExplStatusLineText = '\ '
    "let g:miniBufExplStatusLineText = "%{bufnr('$')}"
    "let g:miniBufExplStatusLineText = "%{fnamemodify(getcwd(),':t')}"
    "let g:miniBufExplStatusLineText = "%{PrintCurrFolder()}"

    " Put MBE in vert, with colm 20
    let g:miniBufExplVSplit = 1

    " Put MBE in left
    let g:miniBufExplBRSplit = 0

    let g:miniBufExplAutoStart = 0
