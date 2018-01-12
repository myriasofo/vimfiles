" Clone of EasyMotion - just faster

fun! EasyKey(modes, nJumpKeys)
    "echo "Pick text to jump to:"
    let moveTo = ProcessChar()
    if moveTo == "\<esc>"
        return
    endif
    normal! mE


    if &filetype == 'help' || &filetype == 'netrw'
        setlocal noreadonly
        setlocal modifiable
    elseif bufname('%') != "[Command Line]"
        " Save old history (bc setline below will change it)
        exe "wundo " . g:dir_vim . "tempUndoHistory"
    endif

    " Prep for line-by-line insertion of jumpKeys
    call s:initJumpKeys(a:nJumpKeys)
    let matchDct = {}
    let firstChange = 0
    let jumpHighlights = []
    call add(jumpHighlights, matchadd("Blackout", '\m\%>0l'))
    "call add(jumpHighlights, matchadd("Blackout", '\m\%>'.nTop.'l.\%<'.nBot.'l'))
    
    " Insert jumpKeys here
    for lnum in s:getVisibleLines()
        let [indText, ind, charArr] = s:splitLineText(lnum)
        let newCharArr = s:insertJumpKeys(moveTo, lnum, charArr, ind, matchDct, jumpHighlights)

        if newCharArr != charArr
            call setline(lnum, indText.join(newCharArr, ''))

            if firstChange == 0
                let firstChange = IsFolded(lnum) ? lnum : -1
            endif
        endif
    endfor

    " PART 2 NEEDS: firstChange, jumpHighlights, matchDct
    " Now get input for jump
    redraw
    "echo "Pick match-key to jump to:"
    let userJump1 = ProcessChar()
    if has_key(matchDct, userJump1) || userJump1 == "\<esc>"
        let userJump = userJump1
    else
        let userJump2 = ProcessChar()
        let userJump = userJump1.userJump2
    endif

    " Reverse everything to what it was before (rundo is critical!)
    silent undo

    " Above 'undo' jumps to top change and opens fold, so close it back
    if line('.') == firstChange
        foldclose
    endif
    normal! `E

    if &filetype == 'help' || &filetype == 'netrw'
        setlocal nomodifiable
        setlocal readonly
    elseif bufname('%') != "[Command Line]"
        try
            silent exe "rundo " . g:dir_vim . "tempUndoHistory"
        catch
            " wundo will produce nothing if NO undo history, causing rundo to crash
            " so we simulate the above by just resetting the undo history
            echom "ERROR: No prev undo history, so clearing all undo history"
            call ClearAllUndoHistory()
        endtry

    endif

    for hl in jumpHighlights
        call matchdelete(hl)
    endfor

    " Finally, actually jump
    if has_key(matchDct, userJump)
        let [jumpLine, jumpCol] = matchDct[userJump]
        if a:modes == 'o'
            normal! v
        elseif a:modes == 'v'
            normal! gv
        elseif a:modes == 'n'
            " no special behavior for normal mode
        endif
        call cursor(jumpLine, jumpCol)
    endif
endfun

fun! s:insertJumpKeys(moveTo, lnum, charArr, ind, matchDct, jumpHighlights)
    let newCharArr = copy(a:charArr)
    let skip = 0
    let counter = -1
    let offsetForTab = 0

    for j in range(len(a:charArr))
        let char = a:charArr[j]

        " Manage tabs for skip
        let tabsize = 0
        let counter += 1
        if char == "\t"
            let tabsize = &tabstop - counter
            let counter = -1
        else
            let counter = counter % &tabstop
        endif

        if skip "For two-letter jump
            if tabsize >= 2
                let newCharArr[j] = "\t"
                let offsetForTab += 1
            else
                let newCharArr[j] = ''
            endif
            let skip -= 1

        elseif char == a:moveTo
            let jumpKey = s:getNextJumpKey()
            if jumpKey == ""
                break
            endif

            let newCharArr[j] = jumpKey

            let colm = 1 + a:ind + j
            let a:matchDct[jumpKey] = [a:lnum, colm]
            let colm += offsetForTab

            if len(jumpKey) == 1
                call add(a:jumpHighlights, matchadd("JumpKey_single", '\m\%'.a:lnum.'l\%'.colm.'c'))
            elseif len(jumpKey) == 2
                call add(a:jumpHighlights, matchadd("JumpKey_double1", '\m\%'.a:lnum.'l\%'.colm.'c'))
                call add(a:jumpHighlights, matchadd("JumpKey_double2", '\m\%'.a:lnum.'l\%'.(colm+1).'c'))
                let skip = 1
            endif

        endif
    endfor
    return newCharArr
endfun

fun! s:splitLineText(lnum)
    let lineText = getline(a:lnum)

    " Separating indent from text
    let indText = ''
    let ind = 0
    let nWhitespace = indent(a:lnum)

    if nWhitespace > 0
        if match(lineText, '\t') == -1
            let ind = nWhitespace
            let indText = repeat(' ', ind)
            let lineText = lineText[(ind):]
        else
            let ind = match(lineText, '\S')
            let indText = lineText[0:(ind-1)]
            let lineText = substitute(lineText, '^\s\+', '', '')
        endif
    endif
    let charArr = split(lineText, '\zs')
    return [indText, ind, charArr]
endfun

fun! s:getVisibleLines()
    " WHY - slightly complicated bc of folded regions
    let visibleLines = []

    let iter = line('w0')
    for i in range(winheight(0))
        call add(visibleLines, iter)

        let iter = GetFoldEnd(iter) + 1
        if iter > line('$')
            break
        endif
    endfor

    return visibleLines
endfun

fun! s:initJumpKeys(nJumpKeys)
    let s:indexJumpKey = -1

    let jumpKeyVarName = "s:EasyKey_jumpKeys".a:nJumpKeys
    if exists(jumpKeyVarName)
        exe "let s:jumpKeys = ".jumpKeyVarName
    endif

    " Initial creation of jumpKeys
    let keyArr = []
    if a:nJumpKeys == 1
        for char in split(g:EasyKey_lefthand.g:EasyKey_righthand, '\zs')
            call add(keyArr, char)
        endfor

    elseif a:nJumpKeys == 2
        " Todo - could also add 'space' to charLeft. hmmm
        " Could do mix of single + double

        " JUST doubles
        let charLeft = split(g:EasyKey_lefthand, '\zs')
        let charRight = split(g:EasyKey_righthand, '\zs')
        for char in charLeft + charRight
            call add(keyArr, char.char)
        endfor
        for char1 in charLeft
            for char2 in charRight
                call add(keyArr, char1.char2)
            endfor
        endfor
        for char1 in charRight
            for char2 in charLeft
                call add(keyArr, char1.char2)
            endfor
        endfor
        for char1 in charLeft
            for char2 in charLeft
                if char1 != char2
                    call add(keyArr, char1.char2)
                endif
            endfor
        endfor
        for char1 in charRight
            for char2 in charRight
                if char1 != char2
                    call add(keyArr, char1.char2)
                endif
            endfor
        endfor
    endif
    exe "let ".jumpKeyVarName." = keyArr"
    let s:jumpKeys = keyArr
endfun

fun! s:getNextJumpKey()
    let s:indexJumpKey += 1
    return (s:indexJumpKey >= len(s:jumpKeys) ? "" : s:jumpKeys[s:indexJumpKey])
endfun


" Settings
    " Letters for jumpKeys
    "let g:EasyKey_jumpKeys = 'abcdefghijklmnopqrstuvwxyz123456790ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+'
    "let g:EasyKey_jumpKeys = 'abcdefghijklmnopqrstuvwxyz123456790ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    "let g:EasyKey_jumpKeys = 'abcdefghijklmnopqrstuvwxyz'
    "let g:EasyKey_jumpKeys = 'fdsabceghijklmnopqrtuvwxyz'
    "let g:EasyKey_jumpKeys = ' fdsabceghijklmnopqrtuvwxyz'
    "let g:EasyKey_jumpKeys = 'fdsavcregwxtbjklnmuiho'
    let EasyKey_lefthand = 'asdfgvcrewxt3'
    let EasyKey_righthand = 'jklmuiohny'

    " For highlighting jumpKey matches
    "hi Blackout term=NONE gui=NONE guifg=fg
    hi link Blackout StatusLineNC
    hi link JumpKey_single  StatusLine
    if &background == "dark"
        hi link JumpKey_double1 Special
        hi link JumpKey_double2 Type
    else
        hi link JumpKey_double1 DiffDelete
        hi link JumpKey_double2 DiffText
    endif

    " Key bindings
    nmap <silent> f :call EasyKey('n', 2)<cr>
    vmap <silent> f :<c-u>call EasyKey('v', 2)<cr>
    omap <silent> f :call EasyKey('o', 2)<cr>

    " OLD: Easymotion
        "map h <plug>(easymotion-bd-jk)
        map F <plug>(easymotion-s2)
        "map F <plug>(easymotion-s)
        "map  ' <Plug>(easymotion-sn)
        "map  n <Plug>(easymotion-next)
        "map  N <Plug>(easymotion-prev)

        " Letters for easymotion
        "" command tower (hit h, then hit lhs/sp-lhs/h-lhs)
            let g:EasyMotion_keys = 'asdwerxcvzqtb3gf h'
            let g:EasyMotion_keys = 'asdwerxcvzqtb3gfh '
        "" simple (hit h, then hit any/sp-any)
            "let g:EasyMotion_keys = 'asdfgqwertzxcvbjkl;yuiopnm,. h '
        "" easy first (hit h, then hit /lhs/sp-lhs/sp-rhs/rhs
            "let g:EasyMotion_keys = 'asdfgqwertzxcvb jkl;yuiopnm,.h '

