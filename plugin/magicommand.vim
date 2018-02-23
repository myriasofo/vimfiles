" TODO: rename mbe to magi

" Constants
let g:magiLayoutMode = 2
let s:leftPadding = 4
let s:minimumWidth = 7
let s:ignoredFiles = [
    \'glas.to',
    \'stable.to',
    \'flux.to',
    \'list.to',
    \'temp1.to',
    \'temp2.to',
    \
    \'timeLog.to',
    \'vimrc',
    \]

let s:decantFiles = [
    \'temp1.to',
    \'temp2.to',
    \]

let s:mapPaletteFiles = {
    \'stable.to':  'A',
    \'flux.to':    'B',
    \'list.to':    'C',
    \'temp1.to':   '1',
    \'temp2.to':   '2',
    \'timeLog.to': 'L',
    \}

let s:glasConfigLocation = g:dir_notes . '_configs/glas.to'
let s:hotkeysToBufPaths = {}

" Settings for MBE
    let g:miniBufExplStatusLineText = '\ '
    "let g:miniBufExplStatusLineText = "%{bufnr('$')}"
    "let g:miniBufExplStatusLineText = "%{fnamemodify(getcwd(),':t')}"
    "let g:miniBufExplStatusLineText = "%{PrintCurrFolder()}"

    " Put MBE in vert, with colm 20
    let g:miniBufExplVSplit = 1

    " Put MBE in left
    let g:miniBufExplBRSplit = 0

    let g:miniBufExplAutoStart = 0


" Helper functions
function! s:layoutOne(bufNums)
    let [l:hiddenBufs, l:visibleBufs] = s:divideBufsIntoHiddenAndVisible(a:bufNums)

    let magiList = []

    call add(magiList, '')
    call s:addBufs(magiList, l:visibleBufs)

    " Usually use have 2 wins. So if only one, then add an extra linebreak
    if len(l:visibleBufs) == 1
        call add(magiList, '')
    endif
    call add(magiList, '')

    "call s:addGlasBufs(magiList)
    call s:addSpecialBufs(magiList)
    call s:addBufs(magiList, l:hiddenBufs)

    return magiList
endfunction

function! s:layoutTwo(bufNums)
    let [l:special, l:remaining] = s:divideBufsIntoSpecialAndRemaining(a:bufNums)

    let magiList = []

    "call add(magiList, '')
    "call add(magiList, '    Special')
    "call s:addSpecialBufs2(magiList)
    "call s:addBufs(magiList, l:special)
    call s:addGlasBufs(magiList)

    call add(magiList, '    # Remaining')
    call s:addSpecialBufs2(magiList)
    call s:addBufs(magiList, l:remaining)

    return magiList
endfunction

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

function! s:addGlasBufs(magiList)
    "Add all from current glas palette (global var)

    let l:glasRaw = []

    let l:skip = 0
    for l:rawLine in s:getGlasConfig()
        let l:line = substitute(l:rawLine, '^\s\+', '', '')
        let l:firstChar = l:line[0]

        if l:firstChar == '/'
            let l:skip = 0
            continue
        elseif l:firstChar == '*'
            let l:skip = 1
            continue
        elseif l:skip
            continue
        elseif l:firstChar == '' || l:firstChar == '('
            continue
        endif

        call add(l:glasRaw, l:line)
    endfor


    let l:rootPath = ''
    let l:folderPath = ''
    let l:folderStub = ''
    for l:line in l:glasRaw
        let l:firstChar = l:line[0]
        let l:content = StripWhitespace(l:line[1:])

        if l:firstChar == '@' "Set root path
            let l:parts = split(l:content, ':')
            let l:rootPath = StripWhitespace(l:parts[1])

        elseif l:firstChar == '$' "Display this text on mbe
            let l:stub = s:getLeftPadding() . l:content
            call add(a:magiList, l:stub)

        elseif l:firstChar == '#' "Folder
            let l:parts = split(l:content, ':')
            let l:folderDesc = StripWhitespace(l:parts[0])
            let l:rawFolderPath = StripWhitespace(l:parts[1])

            let l:folderPath = substitute(l:rawFolderPath, '{root}', l:rootPath, '')
            let l:folderStub = s:getLeftPadding() . '# ' . l:folderDesc
            let l:addFolder = 1

        else "File
            if l:folderStub != ''
                call add(a:magiList, '')
                call add(a:magiList, l:folderStub)
                let l:folderStub = ''
            endif

            "s:bufUniqNameDict[l:i] "TODO: get unique name?
            let l:path = l:folderPath . '/' . l:line
            let l:stub = s:createStub(l:path, l:line)
            call add(a:magiList, l:stub)
        endif
    endfor

    call add(a:magiList, '')

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
    "let special = ['flux.to', 'list.to', 'temp1.to', 'temp2.to']
    "for tail in special
    "  let path = fnamemodify(g:dir_palettes . tail, ':p')
    "  call add(a:magiList, s:createStub(path, tail))
    "endfor


    " version 2
    " Hard to tell what's going on
    "let special = ['temp1.to', 'temp2.to', 'flux.to', 'list.to']
    "let tempFiles = {'temp1.to': 1, 'temp2.to': 2}
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
    let special = ['temp1.to', 'temp2.to']
    for tail in special
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
    return bufloaded(a:path) ? getbufline(a:path, 0, a:nLines) : readfile(a:path, 0, a:nLines)
endfunction

function! s:getMbeHotkey(path)
    " char "a" is 97 and "z" is 122
    let letter = nr2char(97 + len(s:hotkeysToBufPaths))
    let s:hotkeysToBufPaths[letter] = fnameescape(a:path)
    return letter
endfunction

function! s:getMbeMarker(path)
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
        return s:getMbeHotkey(a:path) . ' '
    endif
endfunction

function! s:hasElement(myList, elem)
    return index(a:myList, a:elem) != -1
endfunction

function! s:getStubMargin(path)
    let l:marker = s:getMbeMarker(a:path)
    let l:padding = s:getLeftPadding(strlen(l:marker) * -1)
    return l:padding . l:marker
endfunction

function! s:isBufModified(path)
    return bufloaded(a:path) && getbufvar(bufnr(a:path), '&modified')
endfunction

function! s:getGlasConfig()
    try
        return readfile(s:glasConfigLocation)
    catch
        return []
    endtry
endfunction

function! s:isSpecialBuf(bufNum)
    if type(a:bufNum) == 0
        let a:path = expand('#'.a:bufNum.':p')
    else
        let a:path = a:bufNum
    endif

    return (
        \s:hasElement(s:ignoredFiles, fnamemodify(a:path, ':t'))
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
        exe 'bd ' . filePath
        return
    endif

    echom "ERROR: No such key for buffer"
endfun

function! MagiGetViewerList(bufNums, bufUniqNameDict)
    let s:bufUniqNameDict = a:bufUniqNameDict
    let s:hotkeysToBufPaths = {}
    let s:loadedBufs = {}

    if g:magiLayoutMode == 1
        return s:layoutOne(a:bufNums)
    else
        return s:layoutTwo(a:bufNums)
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

function! IsMBEOpen()
    return getwinvar(1, '&filetype') == 'minibufexpl'
    "return (bufname(winbufnr(1)) == "-MiniBufExplorer-")
    " alt: could check each win and see if any are
    "for i in winnr('$')
endfun


" External Tools
function! s:refreshMbe()
    if IsMBEOpen() == 0
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
    call s:refreshMbe()
endfun

function! s:glasClear(nStart, nEnd)
    let skip = 0
    for i in range(a:nStart, a:nEnd)
        let rawLine = getline(i)
        let line = StripWhitespace(rawLine)
        if len(line) == 0
            continue
        endif
        let firstChar = line[0]


        if firstChar == '/'
            let skip = 0
            continue
        elseif firstChar == '*'
            let skip = 1
        endif

        if skip == 1
            continue
        endif

        if firstChar == '(' || firstChar == '@' || firstChar == '#'
            continue
        endif

        call tcomment#Comment(i, i)
    endfor

    write
    MbeRefresh
endfunction


command! MbeRefresh call s:refreshMbe()
command! GlasToggle call s:glasToggle()
command! -range=% GlasClear call s:glasClear(<line1>, <line2>)
