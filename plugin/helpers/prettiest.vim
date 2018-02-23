" WHAT - Format text in braces (both json and fctn calls)
" Todo - Diff version for visual selection
    " add keymap for currentLine vs. multiLine (via selection) vs. fragment (via selection)
    " add operator to be used with f?
    " do NOT need for fragment => think! breaking up higher-level line will make fragment into newline

    " perhaps add auto compress?
    " might be unnecessary. IDK

" formatter is amazing for all code, not just json! 
    " consider whether or not to use paren
    " but make version that ignores brackets and paren for small
    " !!! how? I think only looks at top paren/bracket/braces and then only commas
    " if you want to expand parts of it, then you select those particle lines


fun! FormatJson(nStart, nEnd)
    let lines = []
    for line in getline(a:nStart, a:nEnd)
        call add(lines, substitute(line,'^\s\+','',''))
    endfor
    let lineText = join(lines, "\r") " SPECIAL: force a newline between each line

    " STEP 1. insert newlines
    let jsonLines = []
    let skip = 0
    let startIndex = 0
    let delimNum = 0
    let charArr = split(lineText, '\zs')
    for i in range(len(charArr))
        let char = charArr[i]

        " Be careful to skip anything within quotes
        if char == '"'
            let skip = !skip
        elseif skip == 1
            " do nothing until next quote

        " If not within quotes
        else
            " Remove all extra whitespace
            if char == ' '
                let charArr[i] = ''
            " Prettify
            elseif char == ':'
                let charArr[i] = ': '
            " SPECIAL - insert return if this symbol is here
            elseif char == "\r"
                let jsonLine = join(charArr[(startIndex):(i-1)], '')
                call add(jsonLines, jsonLine)
                let startIndex = i + 1

            " Insert newline after
            elseif char == ',' || char == '{' || char == '[' || char == '('
                let jsonLine = join(charArr[(startIndex):(i)], '')
                call add(jsonLines, jsonLine)
                let startIndex = i + 1
                if char != ','
                    let delimNum += 1
                endif

            " Insert newline before
            elseif char == '}' || char == ']' || char == ')'
                let jsonLine = join(charArr[(startIndex):(i-1)], '')
                call add(jsonLines, jsonLine)
                let startIndex = i

                let delimNum -= 1
                if delimNum == 0
                    call add(jsonLines, char) 
                    let startIndex += 1
                endif

            endif
        endif
    endfor

    " Add any trailing text (json shouldn't have, but allowed here)
    if startIndex < len(charArr)
        let jsonLine = join(charArr[(startIndex):-1], '')
        call add(jsonLines, jsonLine)
    endif


    " STEP 2. add indent
    let jsonFinal = []
    let delimStack = []
    let depth = indent('.') / &shiftwidth

    for line in jsonLines
        let skip = 0
        let addLater = 0
        let charArr = split(line, '\zs')
        for i in range(len(charArr))
            let char = charArr[i]
            if char == '"'
                let skip = !skip
            elseif skip == 1
                " do nothing until next quote

            " Add to stack if new brace
            elseif char == '{' || char == '[' || char == '('
                call add(delimStack, char)
                let addLater = 1

            " Remove if matching brace
            elseif (char == '}' && delimStack[-1] == '{')
                \ || (char == ']' && delimStack[-1] == '[')
                \ || (char == ')' && delimStack[-1] == '(')
                call remove(delimStack, -1)
                let depth -= 1
            endif
        endfor

        let indentedLine = repeat(' ', depth * &shiftwidth) . line
        call add(jsonFinal, indentedLine)

        if addLater 
            let depth += 1
        endif
    endfor


    " Finally append
    call append(a:nEnd, jsonFinal)
    " Delete old
    exe a:nStart . ',' . a:nEnd . 'delete'
    return

endfun

fun! FormatFctnCall()

    " work on conditionals? (&& and >=)
    " work on prop chains? obj.prop.prop
    " Simply open only first set of paren
    " Then split by comma only

    let lineNum = line('.')
    let lineText = getline(lineNum)
    let lineText = substitute(lineText,'^\s\+','','')

    " STEP 1. insert newlines
    let jsonLines = []
    let skip = 0
    let startIndex = 0
    let charArr = split(lineText, '\zs')
    let firstParen = 0

    let skipStack = []
    for i in range(len(charArr))
        let char = charArr[i]

        " Be careful to skip anything within quotes
        if len(skipStack) > 0
            "echo 'skip end'
            "echo char
            if (char == '"' && skipStack[-1] == '"')
            \ || (char == ')' && skipStack[-1] == '(')
            \ || (char == ']' && skipStack[-1] == '[')
            \ || (char == '}' && skipStack[-1] == '{')
                call remove(skipStack, -1)
                "let skip = !skip
            endif
        elseif char == '"' || (firstParen && char == '(') || char == '[' || char == '{'
            "echo 'skip start'
            "echo char
            call add(skipStack, char)

        " If not within quotes
        else
            " Remove all extra whitespace
            "if char == ' '
            if char == ' ' && charArr[i-1] == ','
                let charArr[i] = ''
            " Prettify
            "if char == ':'
            "    let charArr[i] = ': '

            " Insert newline after
            elseif !firstParen && char == '('
                let firstParen = 1
                let jsonLine = join(charArr[(startIndex):(i)], '')
                call add(jsonLines, jsonLine)
                let startIndex = i + 1
            elseif char == ',' 
                let jsonLine = join(charArr[(startIndex):(i)], '')
                call add(jsonLines, jsonLine)
                let startIndex = i + 1

            elseif char == ')'
                let lastParen = i
            endif
        endif
    endfor

    let jsonLine = join(charArr[(startIndex):(lastParen-1)], '')
    call add(jsonLines, jsonLine)
    let jsonLine = join(charArr[(lastParen):-1], '')
    call add(jsonLines, jsonLine)

    "echo jsonLines
    "return


    " STEP 2. add indent
    let jsonFinal = []
    let delimStack = []
    let depth = indent('.') / &shiftwidth
    let firstParen = 0

    for line in jsonLines
        if line == jsonLines[-1]
            let depth -= 1
        endif

        let indentedLine = repeat(' ', depth * &shiftwidth) . line
        call add(jsonFinal, indentedLine)

        if !firstParen && match(line, '(')
            let firstParen = 1
            let depth += 1
        endif
    endfor


    " Finally append
    call append(lineNum, jsonFinal)
    " Delete old
    exe lineNum . 'delete'
    return

endfun

fun! CompressLine(modes)
    " Fold is easiest => just go on the line and run
    " Visual => select all. then CANCEL. then run 
    " If not folded, then do visual.
    " But note, if want to do visual, must NOT be on a folded line!

    if a:modes == 'v'
        let nStart = line("'<")
        let nEnd = line("'>")
    elseif a:modes == 'fold'
        let nStart = GetFoldStart(line('.'))
        let nEnd = GetFoldEnd(line('.'))
    endif

    let textArr = []
    for text in getline(nStart, nEnd)
        call add(textArr, substitute(text, '^\s\+', '', ''))
    endfor
    let textStr = repeat(' ', indent(nStart)) . join(textArr, '')

    call append(nEnd, textStr)
    exe nStart.','.nEnd.'delete'
endfun


command! -range FormatJson call FormatJson(<line1>, <line2>)
"command! FormatJsonVisual call FormatJson('v')
command! CompressLine call CompressLine('fold')
command! CompressLineVisual call CompressLine('v')

" Test cases (json)
    ""{a:1}
    ""!{a:1,a:2}
    ""!f({a:1})
    ""{a:1,a:{b:2}}
    ""!{a:1,a:{b:2,b:3}} 
    ""{a:1,a:[b]}
    ""!{ a: 1, a: [ b, b ] } 
    ""{a:1,a:[{c:2}]}
    ""!{ "a": 1, "a": [ { "c": 2 }, { "c": 3 } ] }
    ""{ "one space here": "more | here", a: [ { c: 2, c: { d: 3 } , c: [ d ] } , { c: 4, c: { d: 5 } , c: [ d ] } ] }

" Test cases (fctn calls)
    ""f(a,b)
    ""f(a,"b,b")
    ""f(a,"b,b",f(a,"c,d"))
    ""f(a, "b,b", f(a,"c,d"), {a:b,"c,d",a}, [a,b,{}])  
