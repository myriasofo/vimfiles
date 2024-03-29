
" Expected format for file
    " $ text to display
    " ( comment
    " % file link (eg. 'linkName: filePath')
    " : use to split linkName vs filePath
    " { for filePath, use a vim varaible for path (eg. {g:dir_notes}/dilig.to)
    " @ command to execute

    let s:CHAR_DISPLAY_TEXT = '$'
    let s:CHAR_COMMENT = '('
    let s:CHAR_FILELINK = '%'
    let s:CHAR_FILELINK_SPLIT = ':'
    let s:CHAR_FILELINK_VAR_LEFT = '{'
    let s:CHAR_FILELINK_VAR_RIGHT = '}'
    let s:PADDING_LEFT = '  '

    " Settings
    let g:Spacework#configLocation = g:dir_notes . '_configs/spacework.to'
    let s:jumpKeysAvailable = 'abcdefghijmnopqrstuvwxyz123'

fun! Spacework()
    let [l:toPrint, l:mapKeyToFile] = Spacework#ExtractConfig()
    call s:printDialog(l:toPrint)
    call s:getInput(l:mapKeyToFile)
    redraw "To stop 'Press ENTER or...'
endfun


fun! Spacework#ExtractConfig()
    let l:toPrint = []
    let l:mapKeyToFile = {}
    let jumpKeys = split(s:jumpKeysAvailable, '\zs')

    for l:line in s:readConfig()
        let line = StripWhitespace(l:line)
        let firstChar = line[0]

        if firstChar == s:CHAR_COMMENT
            continue

        elseif firstChar == ''
            call add(toPrint, '')

        elseif firstChar == s:CHAR_DISPLAY_TEXT
            call add(toPrint, line[2:])

        elseif firstChar == s:CHAR_FILELINK
            let [filePath, fileDisplayText, jumpKey] = s:extractFileDetails(line, jumpKeys)
            let l:mapKeyToFile[jumpKey] = filePath
            call add(toPrint, jumpKey . ': ' . StripWhitespace(fileDisplayText))

        else
            call add(toPrint, 'ERROR: Bad line - ' . line)
        endif
    endfor

    return [l:toPrint, l:mapKeyToFile]
endfun

fun! s:readConfig()
    try
        return readfile(g:Spacework#configLocation)
    catch
        return []
    endtry
endfun

fun! s:extractFileDetails(line, jumpKeys)
    let [fileDisplayText, filePath] = SplitOnce(a:line[1:], s:CHAR_FILELINK_SPLIT)

    let filePath = StripWhitespace(filePath)
    if filePath[0] == s:CHAR_FILELINK_VAR_LEFT
        let [varName, remainingPath] = SplitOnce(filePath[1:], s:CHAR_FILELINK_VAR_RIGHT)
        let filePath = eval(varName) . remainingPath
    endif

    if fileDisplayText[0] == ' '
        let jumpKey = s:getNextJumpKey(a:jumpKeys)
    else
        let jumpKey = fileDisplayText[0]
        let fileDisplayText = fileDisplayText[1:]
        call s:removeJumpKey(a:jumpKeys, jumpKey)
    endif

    return [filePath, fileDisplayText, jumpKey]
endfun

fun! s:removeJumpKey(jumpKeys, jumpKey)
    let l:iKey = index(a:jumpKeys, a:jumpKey)

    if l:iKey == -1
        echo "ERROR: spacework has duplicate reserved key: |" . a:jumpKey ."|\n\n"
    endif

    call remove(a:jumpKeys, l:iKey)
endfun

fun! s:getNextJumpKey(jumpKeys)
    return remove(a:jumpKeys, 0)
endfun

fun! s:printDialog(toPrint)
    for line in a:toPrint
        echo s:PADDING_LEFT . l:line . "\n"
    endfor
endfun

fun! s:getInput(jumpList)
    while 1
        let char = ProcessChar()

        if has_key(a:jumpList, char)
            let filePath = a:jumpList[char]
            call OpenFile(filePath)
            return

        elseif char == "\<esc>"
            return

        else
            echo '  ERROR: "'.char.'" is not a key. Press <esc> or try again: '
        endif

    endwhile
endfun


