
let s:LEFT_PADDING = '  '
let s:RIGHT_PADDING = ' '
let s:MATCH_PADDING = ' '

function! Scroller() abort
    return s:LEFT_PADDING
        \. s:createScroller()
        \. s:createLineNumberBlock()
endfunction

function! ScrollerMatchLines()
    let matchingLines = range(1, line('$'))
        \->filter('getline(v:val) =~ @/')
    let b:Scroller_nMatches = len(matchingLines)

    let b:Scroller_indicesOfMatches = {}
    let b:Scroller_lineNumsOfMatches = {}
    for lineNum in matchingLines
        let iMatch = s:getScrollerPosition(lineNum)
        let b:Scroller_indicesOfMatches[iMatch] = 1
        let b:Scroller_lineNumsOfMatches[lineNum] = 1
    endfor
endfunction


function! s:createScroller()
    let scrollerLen = s:getScrollerBodyLength()

    if scrollerLen <= 0
        return ''
    endif
    
    " Hide scrollbar for files w/o many lines (ie smaller than window height)
    if line('$') < winheight(0)
        return repeat(' ', scrollerLen + 2)
    endif

    " Mark matches for search
    let scrollArr = ListFill(scrollerLen, ' ')
    if exists("b:Scroller_indicesOfMatches")
        for iMatch in keys(b:Scroller_indicesOfMatches)
            if iMatch >= len(scrollArr)
                let iMatch = len(scrollArr) - 1
            endif

            let scrollArr[iMatch] = '_'
        endfor
    endif

    let [cursorIndex, cursorChar] = s:getScrollerCursor()
    let scrollArr[cursorIndex] = cursorChar

    return '(' . join(scrollArr,'') . ')' . s:getMatchCount()
endfunction

function! s:createLineNumberBlock()
    let currLine = line('.') <= 9999 ? line('.') : AddThousandSeparator(line('.'))
    let totalLine = line('$') <= 9999 ? line('$') : AddThousandSeparator(line('$'))
    let padding = repeat(' ', len(totalLine) - len(currLine))
    return s:RIGHT_PADDING
        \. padding 
        \. currLine . '/' . totalLine
endfunction

function! s:getScrollerBodyLength()
    let scrollerLen = winwidth(0)
        \ - len(s:LEFT_PADDING)
        \ - len(s:getMatchCount())
        \ - len(s:createLineNumberBlock())
        \ - 2 "For two parens
    
    if scrollerLen < 0
        let scrolerLen = 0
    endif

    return scrollerLen
endfunction

function! s:getScrollerCursor()
    if line('.') == 1
        let cursorIndex = 0
        let cursorChar = 'T'
    elseif line('.') == line('$')
        let cursorIndex = -1
        let cursorChar = 'B'
    else
        let percPosition = 1.0 * line('.') / line('$') "Be careful of ints vs floats
        let cursorIndex = s:getScrollerPosition(line('.'))
        let cursorChar = float2nr(10.0 * percPosition)
    endif

    if exists("b:Scroller_lineNumsOfMatches") && has_key(b:Scroller_lineNumsOfMatches, line('.'))
        let cursorChar = '|'
    endif

    return [cursorIndex, cursorChar]
endfunction

function! s:getScrollerPosition(lineNum)
    return (1.0 * a:lineNum / line('$') * s:getScrollerBodyLength())
        \->float2nr()
endfunction

function! s:getMatchCount()
    if exists("b:Scroller_nMatches")
        return s:MATCH_PADDING . b:Scroller_nMatches
    endif
    return ''
endfunction

