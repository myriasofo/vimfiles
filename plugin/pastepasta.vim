" OVERALL: This plugin allows for intelligent pasting
" FEATURES:
    " Behaves well around folded sections
    " Flexible to different key orders
    " Can do multiple indent changes
    " Default of pasting with matched indent is SUPER nice
    " Same logic and keymaps as sister plugin, PastePasta
    " Deals well with both lines and words (ie. has newlines or not)
    " Deals well with text from online
    " For words, can paste on their own line, eg. rrk
    " Replace selection is very smart


fun! PastePasta()
    " Default values
    let direction = 1
    let resetInd = 1
    let indFromCurr = 0
    let indAdjust = 0
    let extraBlankspace = {'from': 0, 'away': 0}

    " Get input
    while 1
        let char = ProcessChar()
        if char == "\<esc>"
            echom 'PastePasta: Cancelled'
            return

        elseif char == 'k'
            let direction = -1
            break
        elseif char == 'l'
            break
        elseif char == ','
            let indFromCurr = -1
            let direction = -1
            break
        elseif char == '.'
            let indFromCurr = 1
            break

        elseif char == 'j'
            let indAdjust -= &shiftwidth
        elseif char == ';'
            let indAdjust += &shiftwidth

        elseif char == 'r'
            let resetInd = 0
        elseif char == 's'
            let extraBlankspace.from += 1
        elseif char == 'd'
            let extraBlankspace.away += 1

        else
            echom 'PastePasta: Nothing happened'
            return
        endif
    endwhile

    " If fragment (ie. has no newlines)
    if !HasNewlines(@+)
        echom 'paste: no newlines'
        call Paste_fragment(direction, resetInd)
    " If has at least one *newline*
    else
        let indFinal = DetermineIndent(direction, resetInd, indAdjust, indFromCurr)
        let indText = repeat(' ', indFinal)
        call Paste(direction, indText, extraBlankspace)
        "call Paste2(direction, indText, extraBlankspace)
    endif
endfun

fun! Paste_fragment(direction, resetInd)
    " If want to paste on its own line
    if a:resetInd == 0
        let indText = repeat(' ', indent('.'))
        call InsertLine(a:direction, indText)
        
        " NOTE - must move to end, so that paste works right
        call cursor(0, len(indText))
        normal! "+]p
    else
        if a:direction == 1
            normal! "+p
        else
            normal! "+P
        endif
    endif

    " Change view to start of paste
    normal! `[
endfun

fun! ReplaceSelection()
    " Text that is a fragment (ie. no newlines)
    if !HasNewlines(@+)
        echom 'replace: no newlines'
        normal! gv"+p
        return

    " Text from within vim
    elseif @+[-1:] == "\n"
        echom 'replace: from vim'

        " Jump to *start* of visual selection (to use its indent)
        normal! '<

        " Paste text *up*
        normal! "+]P

    " Text from *outside* vim => often messed up
    else
        echom 'replace: from web'

        " Jump to *start* of visual selection (to use its indent)
        normal! '<

        let indFinal = DetermineIndent(-1, 1, 0, 0)
        let indText = repeat(' ', indFinal)
        call InsertLine(-1, indText)

        normal! "+]p
    endif

    let pasteStart = line("'[")
    let pasteEnd = line("']")

    " Delete orig selection
    normal! gv"_d

    call UnfoldAll(pasteStart, pasteEnd)
    call ChangeIndentType(pasteStart, pasteEnd)
    silent! call FoldAll_toIndStart(pasteStart, pasteEnd)
    "call Fold_firstInd(pasteStart, pasteEnd)
endfun

fun! Paste(direction, indText, extraBlankspace)

    " Special case: if last fold in branch, InsertLine will be eaten, so do another
    if IsFolded(line('.')) && a:direction == 1
        let nCurr = GetFoldStart(line('.'))
        let indCurr = GetIndentLvl(nCurr)
        let nBelow = nextnonblank(GetFoldEnd(nCurr)+1)
        let indBelow = (nBelow == 0 ? 0 : GetIndentLvl(nBelow))

        if indBelow < indCurr 
            call InsertLine(a:direction, '')
        endif
    endif

    " Text from web doesn't have newline at very end. While text in vim does
    if @+[-1:] != "\n"
        let @+ .= "\n"
    endif


    " Put in placeholder to paste from (del after paste)
    call InsertLine(a:direction, a:indText)
    normal! mP

    " Option to add extra lines (for padding)
    for i in range(a:extraBlankspace.from)
        call InsertLine(-a:direction, '')
    endfor
    normal! 'P
    for i in range(a:extraBlankspace.away)
        call InsertLine(a:direction, '')
    endfor

    " Actual paste
    normal! 'P
    normal! "+]p
    let pasteStart = line("'[")
    let pasteEnd = line("']")

    " Delete placeholder line
    call UnfoldAll(pasteStart, pasteEnd)
    'P delete
    let pasteStart -= 1
    let pasteEnd -= 1
    call UnfoldAll(pasteStart, pasteEnd)
    call ChangeIndentType(pasteStart, pasteEnd)


    " HARD - Should we add an extra blank? Should we del a blank?
    let pasteAfter = pasteEnd + 1
    let pasteAfter_nonblank = nextnonblank(pasteAfter)
    "let pasteAfter_nonblank = Nextnonblank2(pasteAfter)
    if !IsBlank(pasteEnd)
        " will eat?
        if indent(pasteStart) < indent(pasteEnd)
            " not at branch end?
            if indent(pasteStart) <= indent(pasteAfter_nonblank)
                " If after is blank, will eat it, so must add another
                if IsBlank(pasteAfter)
                    call append(pasteEnd, '')
                    let pasteEnd += 1
                endif
            endif
        endif
    " has eaten?
    else
        let pasteEnd_nonblank = prevnonblank(pasteEnd)
        if indent(pasteStart) < indent(pasteEnd_nonblank)
            " might throw it up? (at branch end)
            if indent(pasteStart) > indent(pasteAfter_nonblank)
                " remove throwup
                call UnfoldAll(pasteStart, pasteEnd)
                exe pasteEnd.'delete'
                let pasteEnd -= 1
                call UnfoldAll(pasteStart, pasteEnd)
            endif
        endif
    endif

    " Clean up what I just pasted
    "if IsFolded(pasteStart)
    "    foldclose
    "endif
    silent! call FoldAll_toIndStart(pasteStart, pasteEnd)
    "call Fold_firstInd(pasteStart, pasteEnd)

    " Head back
    call cursor(pasteStart, 0)
endfun

fun! Paste2(direction, indText, extraBlankspace)
    " Grab clip as arr of lines
    let clip = @+
    let clipArr = split(clip, "\n")

    " Adjust to correct indent
    let indFirst = match(clipArr[0], '\S')
    let indFirstText = repeat(' ', indFirst)
    for i in range(len(clipArr))
        let clipArr[i] = substitute(clipArr[i], indFirstText, a:indText, '')
    endfor

    " Add extra blanks
    for i in range(a:extraBlankspace.away)
        call InsertToList_byDirection(a:direction, clipArr, '')
    endfor
    for i in range(a:extraBlankspace.from)
        call InsertToList_byDirection(-a:direction, clipArr, '')
    endfor

    " Get pos for paste (not same as where cursor comes from)
    let pasteLnum = (a:direction == 1 ? GetFoldEnd('.') : GetFoldStart('.') - 1)
    let firstLineOfText = (a:direction == 1 ? pasteLnum +1 + a:extraBlankspace.from : pasteLnum + 1 + a:extraBlankspace.away)
    
    " TODO: Might eat? might throw it up?
    " If lastline is blank and is the end of a branch
    if clipArr[-1] == ''
        " the line above is end o
    endif

    " should be more elegant if I access the var itself
    " watch out for extraBlankspace

    " Finally, append
    "fun! FakeAction_forUndo()
    "    call setline(line('.'), getline('.'))
    "endfun
    "call FakeAction_forUndo()

    call append(pasteLnum, clipArr)
    call cursor(firstLineOfText, 0)
    "call ChangeIndentType(pasteStart, pasteEnd) "TODO: change this to manipulate the arr itself!
    "silent! call FoldAll_toIndStart(pasteStart, pasteEnd)
endfun
fun! InsertToList_byDirection(direction, arr, insertedItem)
    if a:direction == 1
        call add(a:arr, a:insertedItem)
    elseif a:direction == -1
        call insert(a:arr, a:insertedItem)
    endif
endfun


" This fctn checks and adjusts ind of pasted text
fun! ChangeIndentType(textStart, textEnd)
    " NOTE : Unnecessary to convert tabs (prob bc of 'expandtab')
    let guess = GuessIndentType(a:textStart, a:textEnd)
    if guess.type == 'unknowable'
        return 
    elseif guess.type == 'space' && guess.size != &shiftwidth
        let indPaste = indent(a:textStart)
        for i in range(a:textStart+1, a:textEnd)
            if !IsEmptyspace(i)
                call ConvertSpaceSize(i, indPaste, guess.size, &shiftwidth)
            endif
        endfor
    endif

endfun
fun! GuessIndentType(nStart, nEnd)
    " Return {type: 'space', length: 4}
    " Return {type: 'tab', length: 4}
    " Return {type: 'unknowable', length: -1}
    " Return {type: 'mix', length: -2}

    " Todo - check if mix of tabs and spaces (meh)
    " Todo - check more than just first and second line

    if (a:nEnd-a:nStart) <= 0
        return {'type': 'unknowable'}
    endif


    " Grab first line that's nonempty
    for i in range(a:nStart, a:nEnd)
        if i == a:nEnd
            return {'type': 'unknowable'}
        elseif getline(i) !~ '^\s*$' "if nonempty
            let firstLine = i
            let firstText = getline(i)
            let firstInd = indent(i)
            break
        endif
    endfor

    " Grab second line that's nonblank AND diff ind
    for i in range(firstLine, a:nEnd)
        if getline(i) !~ '^\s*$' && indent(i) != firstInd
            let secondLine = i
            let secondText = getline(i)
            let secondInd = indent(i)
            let indDiff = secondInd - firstInd
            break
        elseif i == a:nEnd
            return {'type': 'unknowable'}
        endif
    endfor

    " Now guess indent type
    if match(secondText, '^\t\+') > 0
        return {'type': 'tab', 'size': indDiff}
    else
        return {'type': 'space', 'size': indDiff}
    endif

endfun

fun! ConvertSpaceSize(lnum, indPaste, sizeOld, sizeNew)
    " Extremely useful when working with tradeweb code

    " Get new ind
    let oldLine = getline(a:lnum)[(a:indPaste):]
    let oldInd = match(oldLine, '\S')
    let indReal = oldInd / a:sizeOld
    let newInd = a:indPaste + indReal * a:sizeNew
    let newIndText = repeat(' ', newInd)

    " Conjoin new ind on old text
    let oldTextOnly = oldLine[(oldInd):]
    let newText = newIndText . oldTextOnly

    call setline(a:lnum, newText)
    if IsFolded(a:lnum)
        exe a:lnum . 'foldopen'
    endif
endfun


" Keymaps
nmap <silent> r :call PastePasta()<cr>
vmap <silent> r :<c-u>call ReplaceSelection()<cr>

