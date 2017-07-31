" NOTE: This plugin reimagines insertions in vim
    "Explanation is easiest by example:
        "As before, i is i
        "Instead of I, use ai
        "Instead of O, use ak
        "Instead of O<tab>, use alk
        "Instead of O<del>, use ahk
        "Instead of O<enter>, use ask
        "Instead of O<tab><tab><tab>, use alllk or a3lk

    "Doesn't seem like an improvement, eh?
        "* Well, it completely avoids use of <tab>, <del>, <shift>, AND <enter>
        "* Really nice for rsi sufferers (ie. me)
        "* Also much faster bc every key is homerow
        "* Even faster bc it's super intuitive to use direction keys
        "* Doesn't use up any new key maps (actually frees up IAO)

    "It has some nice features:
        "* Behaves well around folded sections (actually tricky)
        "* Allows arbitrary indentation, either allk or a3lk or aak or aa3lk
        "* Allow matching indent from curr (default) or above/below (a, or a.)
        "* Allows arbitrary extra lines above/below, either ask or adk or asdk 
        "* Can append without insert mode (ie. to add whitespace)
        "* Same logic and keymaps as sister plugin, PastePasta

    "No keys are mapped by default. Here's what I use
        "let g:Insertatron_easykeymaps = 1
        "let g:Insertatron_key_main = 'a'
        "let g:Insertatron_key_insertLeft = 'i'
        "let g:Insertatron_key_insertRight = 'o'


fun! Insertatron()
    " Start with default settings
    let indLen       = &shiftwidth

    let direction    = 1 "Direction for new lines (insertUp)
    let insertMode   = 1 "MODE: after adding lines, proceed into vim's insert mode
    let matchInd     = 1 "MODE: when adding new lines, give them empty str to match indent of cursor line
    let indFromCurr  = 0 "Get matchInd from next visible line (above or below)

    let extraFrom    = 0 "include additional lines between original cursor and new location
    let extraAway    = 0 "include additional lines between new location and rest of text
    let indAdjust    = 0 "Adjust indent up or down

    " Get input
    while 1
        let char = ProcessChar()

        if char == "\<esc>"
            echom 'Insertatron: Cancelled'
            return

        elseif char == g:Insertatron_key_insertLeft
            call cursor('.', indent('.')+1)
            startinsert
            return
        " NOTE: 'startinsert!' sucks in macvim
        elseif char == g:Insertatron_key_insertRight
            startinsert!
            return

        elseif char == g:Insertatron_key_up
            let direction = -1
            break
        elseif char == g:Insertatron_key_dn
            "let direction = 1 "Default
            break

        "elseif char == g:Insertatron_key_ ','
        "    let indFromCurr = -1
        "    let direction = -1
        "    break
        "elseif char == g:Insertatron_key_ '.'
        "    let indFromCurr = 1
        "    break
        "elseif char=~'\d' "Unneeded
        "    " vim treats str that are numbers as numbers (!)
        "    "let repeat = char

        elseif char == g:Insertatron_key_left
            let indAdjust -= indLen
        elseif char == g:Insertatron_key_right
            let indAdjust += indLen

        elseif char == g:Insertatron_key_main
            let matchInd = 0
        elseif char == g:Insertatron_key_addBlankMode
            let insertMode = 0
            let matchInd = 0

        elseif char == g:Insertatron_key_extraFrom
            let extraFrom += 1
        elseif char == g:Insertatron_key_extraAway
            let extraAway += 1

        else
            echom 'Insertatron: Invalid key'
            return
        endif
    endwhile

    " Grab properly indented line
    let indFinal = DetermineIndent(direction, matchInd, indAdjust, indFromCurr)
    let indText = repeat(' ', indFinal)
    call Inserter(direction, indText, insertMode, extraFrom, extraAway)
endfun

fun! Inserter(direction, indText, insertMode, extraFrom, extraAway)
    " Insert line
    normal! mN
    call InsertLine(a:direction, a:indText)
    normal! mM

    " Add extra lines
    for i in range(a:extraFrom)
        call InsertLine(-a:direction, '')
    endfor
    normal! 'M
    for i in range(a:extraAway)
        call InsertLine(a:direction, '')
    endfor

    " Move to insert mode
    if a:insertMode == 1
        normal! 'M
        startinsert!
    else
        normal! `N
    endif
endfun

fun! DetermineIndent(direction, matchInd, indAdjust, indFromCurr)
    " Adjust ind based on chosen params
    if a:matchInd == 0
        let indFinal = 0

    elseif a:matchInd == 1
        " FEATURE - take ind of above/below
        let nMatch = GetNextVisible('.', a:indFromCurr)

        " FEATURE - blank takes ind of nonblank
        if IsBlank(nMatch)
            if a:direction == 1
                let nMatch = nextnonblank(nMatch)
                "let nMatch = Nextnonblank2(nMatch)
            else
                let nMatch = GetFoldStart( prevnonblank(nMatch) )
            endif
        endif

        let indFinal = indent(nMatch)
    endif

    let indFinal += a:indAdjust
    return indFinal
endfun

fun! InsertLine(direction, content)
    " NOTE: If just need to add lines, use append()
    "       This fctn is here to deal w folding and direction

    " Pick where to append
    let nAppend = GetFoldBounds('.', a:direction)
    if a:direction == -1
        let nAppend -= 1
    endif

    " Append
    call append(nAppend, a:content)
    let nOutput = nAppend + 1
    call cursor(nOutput, 0)

    " If fold eats line..
    if IsFolded(nOutput)
        " When inserting blanklines, add another
        if a:content == ''
            call append(nAppend, "")
            let nOutput += 1
            call cursor(nOutput, 0)
        " For all else, open fold
        else
            foldopen
        endif
    endif
endfun

" Easy key maps
    if exists("g:Insertatron_easykeymaps")
        let g:Insertatron_key_main = 'a'
        let g:Insertatron_key_insertLeft = 'i'
        let g:Insertatron_key_insertRight = 'o'
        let g:Insertatron_key_left = 'j'
        let g:Insertatron_key_up = 'k'
        let g:Insertatron_key_dn = 'l'
        let g:Insertatron_key_right = ';'
        let g:Insertatron_key_addBlankMode = 'f'
        let g:Insertatron_key_extraFrom = 's'
        let g:Insertatron_key_extraAway = 'd'
        exe 'nnoremap ' . g:Insertatron_key_insertLeft . ' i'
        exe 'nnoremap ' . g:Insertatron_key_insertRight . ' a'
        exe 'nmap <silent> ' . g:Insertatron_key_main . ' :<c-u>call Insertatron()<cr>'
    endif


" FORMATTED
