" This provides a scroll bar in the status bar

fun! Scroller()
    " Don't show scrollbar for small files
    if line('$') < winheight(0)
        return ''
    endif

    " Get basic data
    let currLine = line('.')
    let totalLine = line('$')
    let scrollerLen = Scroller_getLength()
    " Note - be *very* careful with floats. Essentially, always do division last
    let perc = 1.0 * currLine / totalLine

    if scrollerLen <= 0
        echom "scrollerLen: ".scrollerLen." winWidth: ".winwidth(0)
        return ''
    endif

    " Index to place position and char to show
    if currLine == 1
        let cursorIndex = 0
        let positionChar = 'T'
    elseif currLine == totalLine
        let cursorIndex = -1
        let positionChar = 'B'
    else
        let cursorIndex = float2nr(perc * scrollerLen)
        let positionChar = float2nr(10.0 * perc)
    endif

    " Constructing scrollbar
    let scrollArr = split(repeat(' ', scrollerLen), '\zs')
    "let scrollerQuarter = scrollerLen/4
    "let scrollArr[scrollerQuarter] = ' '
    "let scrollArr[scrollerQuarter*2] = '|'
    "let scrollArr[scrollerQuarter*3] = ' '

    " Marks search results (orgasmic!)
    let searchNum = ''
    if &hlsearch && exists("b:Scroller_searchPlacement")
        if exists("b:Scroller_searchNum")
            let searchNum = ' ' . b:Scroller_searchNum
        endif

        for placement in b:Scroller_searchPlacement
            if placement < scrollerLen
                let scrollArr[placement] = '_'
                "try
                "    let scrollArr[placement] = '_'
                "catch
                "    echom "ERROR: scroller with len: ".scrollerLen." and placement:".placement
                "endtry
            endif
        endfor
    endif

    let scrollArr[cursorIndex] = (scrollArr[cursorIndex] == ' ') ? positionChar : '|'
    "try
    "    let scrollArr[cursorIndex] = (scrollArr[cursorIndex] == ' ') ? positionChar : '|'
    "catch
    "    echom "ERROR: scroller w len: ".scrollerLen." and cursorIndex: ".cursorIndex
    "endtry
    return '(' . join(scrollArr,'') . ')' . searchNum
endfun

fun! Scroller_getLength()
    if &hlsearch && exists("b:Scroller_searchNum") 
        if b:Scroller_searchNum == 0
            let STATUSLINE_SIZE = 16 + 2
        else
            let STATUSLINE_SIZE = 16 + float2nr(log10(b:Scroller_searchNum)) + 2
        endif
    else
        let STATUSLINE_SIZE = 16
    end
    let SCROLLER_MAX = 80 - STATUSLINE_SIZE 

    "let scrollerLen = 10
    let scrollerLen = winwidth(0) - STATUSLINE_SIZE
    if scrollerLen > SCROLLER_MAX
        let scrollerLen = SCROLLER_MAX
    endif
    return scrollerLen
endfun

fun! Scroller_refreshSearchResults()
    let totalLine = line('$')
    let lineNums = filter(range(1, totalLine), 'getline(v:val) =~ @/')
    let b:Scroller_searchNum = len(lineNums)
    let scrollerLen = Scroller_getLength()

    let placementDct = {}
    for lineNum in lineNums
        if lineNum == 1
            let placementDct[0] = 1
        elseif lineNum == totalLine
            let placementDct[-1] = 1
        else
            let placementDct[float2nr(1.0 * lineNum / totalLine * scrollerLen)] = 1
        endif
    endfor

    let placements = keys(placementDct)
    for i in range(len(placements))
        let placements[i] = str2nr(placements[i])
    endfor
    let b:Scroller_searchPlacement = sort(placements)
endfun

fun! Scroller_triggerRefresh()
    "" useful bc triggers a fctn *after*
    let g:updatetime_prev = &updatetime
    let &updatetime = 200
    "augroup Scroller
        autocmd CursorHold *
            \ call Scroller_refreshSearchResults()
            \ | let &updatetime = g:updatetime_prev
            \ | autocmd! CursorHold
            "\ | augroup! Scroller
    "augroup END
endfun

" NOTE - These cause errors if they don't exist
"call add(g:session_persist_globals, 'b:Scroller_searchPlacement')
"call add(g:session_persist_globals, 'b:Scroller_searchNum')
