
" WHAT - NavKey is a simple way to move thru files


" Main - NavKey function to navigate
fun! NavKey(origDir, indexCurr, overflowPage)
    set nomore
    echo repeat("\n", 1)

    let [nParents, currDir, printParentStr] = s:process_parentDir(a:origDir, a:indexCurr)
    let [jumpList, overflowPage] = s:get_jumps(currDir, a:overflowPage)
    echo '  ' . printParentStr ."\n"
    while s:pick_dir(a:origDir, a:indexCurr, nParents, currDir, jumpList, overflowPage)
    endwhile
endfun

fun! s:process_parentDir(origDir, indexCurr)
    let parentArr = split(a:origDir, g:pathSep)
    let nParents = len(parentArr)
    let indexParent = nParents + a:indexCurr - 1

    let accumDir = has('unix') ? '/' : ''
    let printParentStr = has('unix') ? '/' : ''

    if has('unix')
        let currDir = '/'
        if indexParent == -1
            let printParentStr = '[/]'
        endif
    endif

    for i in range(len(parentArr))
        let parent = parentArr[i]
        let accumDir .= parent . g:pathSep

        if i == indexParent
            let currDir = accumDir
            let printParentStr .= '['.parent.']' . g:pathSep
        else
            let printParentStr .= parent . g:pathSep
        endif
    endfor
    return [nParents, currDir, printParentStr]
endfun

fun! s:get_jumps(currDir, overflowPage)
    " Grab names of dirs and files
    "let nameArr = glob('*', 0, 1) "same slowness as globpath
    echo "\n  NAMES:"
    let nameArr = split( globpath(a:currDir, '*') , '\n') "slow
    let nameArr += split( globpath(a:currDir, '.[^.]*') , '\n') "slow
    "if has('unix')
    "    let nameArr += split( globpath(a:currDir, '.[^.]*') , '\n') "slow
    "    "echo globpath('~/.[^.]*')
    "    "echom glob('`find ~/ -maxdepth 1 -type f`')
    "endif
    let excludedNames = ['CVS', '.DS_Store', '.git']
    call filter(nameArr, 'index(excludedNames, fnamemodify(v:val,":t")) == -1')


    " Separate dirs from files
    let dirArr = filter(copy(nameArr), 'isdirectory(v:val)')
    let fnameArr = filter(copy(nameArr), '!isdirectory(v:val)')
    let nameArr = dirArr + fnameArr

    " Manage overflow
    let availableLetters = len(g:NavKey_jumpKeys)
    let nNames = len(nameArr)
    let startIndex = 0
    let endIndex = availableLetters - 1

    let printEnd = ""
    let overflowPage = a:overflowPage
    if overflowPage < 0
        let overflowPage = 0
        let printEnd = "\n  (already at start)"
    elseif overflowPage > 0
        let startIndex = 0 + availableLetters * overflowPage
        let endIndex = availableLetters * (overflowPage + 1) - 1
        if startIndex >= nNames
            let overflowPage = overflowPage - 1
            let startIndex = 0 + availableLetters * overflowPage
            let endIndex = availableLetters * (overflowPage + 1) - 1
            let printEnd = "\n  (already at end)"
        endif
        if overflowPage > 0
            echo '  <<<'
        endif
    endif
    let nameArr = nameArr[(startIndex):(endIndex)]


    let winHeight = winheight(0)-1
    let jumpList = {}
    for i in range(len(nameArr))
        let name = nameArr[i]
        let tail = fnamemodify(name, ':t')
        let jumpKey = g:NavKey_jumpKeys[i]
        let jumpList[jumpKey] = name
        echo '  ' . (isdirectory(name) ? (jumpKey . ': |' . tail . '|') : (jumpKey . ': ' . tail) )
    endfor

    if endIndex < (nNames-1)
        echo '  >>>'
        "echo '>>>MORE<<<'
    endif
    echo printEnd . "\n"
    "echo "\n"
    return [jumpList, overflowPage]
endfun

fun! s:pick_dir(origDir, indexCurr, nParents, currDir, jumpList, overflowPage)
    let char = ProcessChar()

    if has_key(a:jumpList, char)
        let jumpInstruction = a:jumpList[char]
        if isdirectory(jumpInstruction)
            echo '  '. char
            call NavKey(jumpInstruction, 0, 0)
        else
            exe 'edit ' . jumpInstruction 

            set more
            redraw
        endif

    elseif char == "l"
        call NavKey(a:origDir, a:indexCurr, a:overflowPage+1)
    elseif char == "k"
        call NavKey(a:origDir, a:indexCurr, a:overflowPage-1)

    elseif char == "\<enter>"
        exe 'cd '.a:currDir
        set more
        redraw

    elseif char == "\<esc>"
        set more
        redraw

    elseif char == "\<bs>"
        let newIndex = a:indexCurr - 1
        if newIndex > -a:nParents || (has('unix') && newIndex == -a:nParents)
            call NavKey(a:origDir, newIndex, 0)
        else
            echo "  ERROR: Cannot go back past root"
        endif
    elseif char == "\<del>"
        let newIndex = a:indexCurr + 1
        if newIndex <= 0
            call NavKey(a:origDir, newIndex, 0)
        else
            echo "  ERROR: Cannot go forward past tail"
        endif
    elseif char == " "
        call NavKey_ListBookmarks()
    else
        echo '  ERROR: <' . char . '> is not a key. Press <esc> or try again: '
        return 1
    endif
    return 0
endfun


" For bookmark mode
fun! NavKey_ListBookmarks()
    set nomore
    echo repeat("\n", 2)

    let bookmarks = s:get_bookmarks(s:open_cache())
    call s:pick_bookmark(bookmarks)
endfun

fun! s:get_bookmarks(cache)
    let jumpList = {}
    call s:reset_jumpKey()

    let title = ''
    for i in range(len(a:cache))
        let [dirPath, displayText] = s:extract_bookmarkData(a:cache[i])

        if dirPath == "comment"
            continue
        elseif dirPath == "displayInline"
            echo displayText . "\n"
        elseif dirPath == "displayTitle"
            let title = displayText . '  '
            "let title = '' . displayText .' - '
        else
            let jumpKey = s:getNext_jumpKey()
            let jumpList[jumpKey] = dirPath

            if g:NavKey_titleMode == 'inline'
                echo jumpKey . ': ' . displayText
            else
                let maxTitleLen = s:getMaxStrLen(a:cache, '$') "Redundant here, but helps compartmentalize code
                let filler = repeat(' ', maxTitleLen - len(title) + 1)
                echo filler . title . jumpKey . ': ' . displayText
                let title = ''
            endif
        endif
    endfor
    echo ""

    return jumpList
endfun

fun! s:extract_bookmarkData(bookmark)
    let firstChar = a:bookmark[0]
    if a:bookmark == '' "Display spacing
        let dirPath = "displayInline"
        let displayText = ""

    elseif firstChar == '$' "Display text
        let dirPath = (g:NavKey_titleMode == 'inline' ? "displayInline" : "displayTitle")
        let displayText = a:bookmark[2:]

    elseif firstChar == '(' || firstChar == '=' "Commenting out old dirs
        let dirPath = "comment"
        let displayText = ""

    elseif a:bookmark == 'getcwd'
        let dirPath = getcwd()
        let displayText = (dirPath == g:rootPath ? dirPath : fnamemodify(dirPath, ':t'))
        let displayText = 'cwd (' . displayText . ')'

    elseif a:bookmark == 'win1'
        let bufNum = (IsMBEOpen() ? winbufnr(2) : winbufnr(1))
        let dirPath = (bufNum == -1 ? g:rootPath : expand('#'.bufNum.':p:h'))

        let displayText = (dirPath == g:rootPath ? dirPath : fnamemodify(dirPath, ':t'))
        let displayText = 'win1 (' . displayText . ')'

    elseif a:bookmark == 'win2'
        let bufNum = (IsMBEOpen() ? winbufnr(3) : winbufnr(2))
        let dirPath = (bufNum == -1 ? g:rootPath : expand('#'.bufNum.':p:h'))

        let displayText = (dirPath == g:rootPath ? dirPath : fnamemodify(dirPath, ':t'))
        let displayText = 'win2 (' . displayText . ')'
    else
        let [displayText, dirPath] = split(a:bookmark, ': ')
        let dirPath = strpart(dirPath, match(dirPath, '\S'))
        if dirPath[0] == '~'
            let dirPath = expand('~') . dirPath[1:]
        endif
        "let dirPath = fnamemodify(a:bookmark, ':p')
        "let displayText = (dirPath == 'C:\' ? dirPath : fnamemodify(a:bookmark, ':t'))
    endif

    return [dirPath, displayText]
endfun

fun! s:pick_bookmark(jumpList)
    while 1
        let char = ProcessChar()

        if has_key(a:jumpList, char)
            echo '  ' . char
            let dir = a:jumpList[char]
            if !isdirectory(dir)
                echo "  ERROR: Not a dir: " . dir
            else
                call NavKey(dir, 0, 0)
                return
            endif
        elseif char == "\<esc>"
            set more
            redraw
            return
        else
            echo "  ERROR: <" . char . "> is not a key. Press <esc> or try again:"
        endif
    endwhile
endfun
fun! s:getMaxStrLen(arr, condition)
    let maxStrLen = ''
    for line in a:arr
        if line[0] == a:condition
            let len = len(line)
            if len > maxStrLen
                let maxStrLen = len
            endif
        endif
    endfor
    return maxStrLen
endfun


" Helper functions
fun! s:open_cache()
    " Todo - replace this try-catch with correct conditional
    try
        return readfile(g:NavKey_cacheLocation)
    catch
        return []
    endtry
endfun

fun! s:reset_jumpKey()
    let g:NavKey_counter = -1
endfun

fun! s:getNext_jumpKey()
    let g:NavKey_counter += 1
    return g:NavKey_jumpKeys[g:NavKey_counter]
endfun


" Settings
let g:NavKey_cacheLocation = g:dir_myPlugins . 'cache/navkey.to'
"let g:NavKey_jumpKeys = 'abcdefghijklmnopqrstuvwxyz0123456789'
"let g:NavKey_jumpKeys = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
let g:NavKey_jumpKeys = 'abcdefghijmnopqrstuvwxyz'

let g:NavKey_titleMode = 'columns'
"let g:NavKey_titleMode = 'inline'
let g:pathSep = '/'
"let g:pathSep = has('unix') ? '/' : '\'
let g:rootPath = has('unix') ? '/' : 'C:/'

