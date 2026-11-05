; ==============================================================================
; [ MODULE: DYNAMIC CHEATSHEET PARSER & GUI ]
; ==============================================================================

global cheatGui := ""

ShowCheatSheet() {
    global cheatGui
    
    if (cheatGui) {
        if DllCall("IsWindowVisible", "Ptr", cheatGui.Hwnd) {
            cheatGui.Hide()
        } else {
            cheatGui.Show("AutoSize Center")
            WinActivate("ahk_id " cheatGui.Hwnd)
        }
        return 
    }
    
    ; ==============================================================================
    ; 1. DATA EXTRACTION (Spaced Header Parser)
    ; ==============================================================================
    cheatText := ""
    currentCategory := ""
    currentSubCategory := ""
    
    filesToParse := [
        A_ScriptDir "\Modules\Hotstrings.ahk",
        A_ScriptDir "\Modules\Keybindings.ahk",
        A_ScriptDir "\Modules\FocusEngine.ahk"
    ]
    
    for _, currentFile in filesToParse 
    {
        if !FileExist(currentFile)
            continue
            
        fileData := FileRead(currentFile)
        
        Loop Parse, fileData, "`n", "`r"
        {
            line := Trim(A_LoopField)
            if (line == "" || InStr(line, "[ FUNCTION LIBRARY ]"))
                continue
            
            ; A. Detect Categories (Adds a blank spacer row before each category)
            if (RegExMatch(line, 'i)^\s*;\s*\[(.*?)\]', &match)) {
                currentCategory := Trim(match[1])
                currentSubCategory := ""
                if (cheatText != "")
                    cheatText .= "►SPACER`n"
                cheatText .= "►CAT_TXT:" StrUpper(currentCategory) "`n"
                continue
            }
            ; B. Detect Sub-Categories
            else if (RegExMatch(line, 'i)^\s*;\s*---\s*(.*?)\s*---', &match)) {
                cleanSub := Trim(match[1], " -")
                if (cleanSub != "") {
                    currentSubCategory := cleanSub
                    cheatText .= "►SUB_TXT:  ■ " currentSubCategory "`n"
                }
                continue
            }
            
            ; C. Detect Hotkeys (::) OR Leader Keys (case) - IF THEY HAVE A COMMENT
            if (RegExMatch(line, 'i)(?:\bcase\s+"([^"]+)"|[$#\^!+<>\w]+::).*?;\s*(.*)', &match)) {
                isLeaderKey := (match[1] != "")
                fullComment := Trim(match[2])
                
                if (isLeaderKey) {
                    char := StrUpper(match[1])
                    desc := Trim(RegExReplace(fullComment, "^.*?:", "")) 
                    finalText := "Press " char " -> " desc
                } else {
                    if RegExMatch(fullComment, "^(.*?):\s*(.*)", &parts) {
                        finalText := Trim(parts[1]) " -> " Trim(parts[2])
                    } else {
                        finalText := fullComment
                    }
                }
                
                prefix := (currentSubCategory != "") ? "    ├─ " : "    "
                cheatText .= prefix . finalText . "`n"
            }
        }
    }
    
    ; ==============================================================================
    ; 2. BRUTE-FORCE COLUMN BALANCING (Maximum Font Size Algorithm)
    ; ==============================================================================
    cheatText := RTrim(cheatText, "`n`r")
    lines := StrSplit(cheatText, "`n")
    totalLines := lines.Length
    
    safeBreaks := []
    For index, line in lines {
        if (index == 1)
            continue
            
        isHeader := (SubStr(line, 1, 5) == "►CAT_" || SubStr(line, 1, 5) == "►SUB_")
        prev1 := (index > 1) ? (SubStr(lines[index-1], 1, 5) == "►CAT_" || SubStr(lines[index-1], 1, 5) == "►SUB_" || lines[index-1] == "►SPACER") : false
        
        if !(isHeader || prev1)
            safeBreaks.Push(index)
    }
    
    bestMax := 99999
    bestSplit1 := Max(2, totalLines // 3)
    bestSplit2 := Max(3, (totalLines // 3) * 2)
    
    For _, s1 in safeBreaks {
        For _, s2 in safeBreaks {
            if (s2 <= s1)
                continue
                
            c1 := s1 - 1
            c2 := s2 - s1
            c3 := totalLines - s2 + 1
            
            currentMax := Max(c1, c2, c3)
            
            if (currentMax < bestMax) {
                bestMax := currentMax
                bestSplit1 := s1
                bestSplit2 := s2
            }
        }
    }
    
    cols := [[], [], []]
    colMaxLens := [0, 0, 0]
    currentCol := 1
    
    For index, line in lines {
        if (index == bestSplit1)
            currentCol := 2
        else if (index == bestSplit2)
            currentCol := 3
            
        ; Omit blank spacer if it lands at the very top or bottom of a column
        if (line == "►SPACER") {
            if (index == 1 || index == bestSplit1 || index == bestSplit2 || index == bestSplit1 - 1 || index == bestSplit2 - 1)
                continue
        }
            
        actualLen := StrLen(line)
        if (line == "►SPACER")
            actualLen := 0
        else if (SubStr(line, 1, 9) == "►CAT_TXT:")
            actualLen := StrLen(SubStr(line, 10)) + 10 
        else if (SubStr(line, 1, 9) == "►SUB_TXT:")
            actualLen := StrLen(SubStr(line, 10))
            
        cols[currentCol].Push(line)
        if (actualLen > colMaxLens[currentCol])
            colMaxLens[currentCol] := actualLen
    }
    
    maxRows := Max(cols[1].Length, cols[2].Length, cols[3].Length)
    if (maxRows == 0)
        maxRows := 1
        
    ; ==============================================================================
    ; 3. INDEPENDENT COLUMN LAYER BUILDER (100% Native Consolas Characters)
    ; ==============================================================================
    PadRight(str, len) {
        padLen := len - StrLen(str)
        if (padLen > 0) {
            Loop padLen
                str .= " "
        }
        return str
    }
    
    FormatCell(cellValue, colMax, &outBase, &outCat, &outSub, &outFull) {
        blank := PadRight("", colMax)
        if (cellValue == "" || cellValue == "►SPACER") {
            outBase := blank, outCat := blank, outSub := blank, outFull := blank
            return
        }
        if (SubStr(cellValue, 1, 9) == "►CAT_TXT:") {
            ; Uses pure ASCII '=' and '[ ]' so every glyph has identical Consolas cell width
            txt := "[ " . SubStr(cellValue, 10) . " ]"
            rem := Max(0, colMax - StrLen(txt))
            leftBar := rem // 2
            rightBar := rem - leftBar
            lStr := "", rStr := ""
            Loop leftBar
                lStr .= "="
            Loop rightBar
                rStr .= "="
            outCat  := lStr . txt . rStr
            outBase := blank
            outSub  := blank
            outFull := outCat
            return
        }
        if (SubStr(cellValue, 1, 9) == "►SUB_TXT:") {
            outSub  := PadRight(SubStr(cellValue, 10), colMax)
            outBase := blank
            outCat  := blank
            outFull := outSub
            return
        }
        outBase := PadRight(cellValue, colMax)
        outCat  := blank
        outSub  := blank
        outFull := outBase
    }
    
    colBase := ["", "", ""]
    colCat  := ["", "", ""]
    colSub  := ["", "", ""]
    colFull := ["", "", ""]
    
    Loop 3 {
        cIdx := A_Index
        cMax := colMaxLens[cIdx]
        Loop maxRows {
            rIdx := A_Index
            val := (rIdx <= cols[cIdx].Length) ? cols[cIdx][rIdx] : ""
            b := "", c := "", s := "", f := ""
            FormatCell(val, cMax, &b, &c, &s, &f)
            colBase[cIdx] .= b . "`n"
            colCat[cIdx]  .= c . "`n"
            colSub[cIdx]  .= s . "`n"
            colFull[cIdx] .= f . "`n"
        }
        colBase[cIdx] := StrReplace(RTrim(colBase[cIdx], "`r`n"), "&", "&&")
        colCat[cIdx]  := StrReplace(RTrim(colCat[cIdx],  "`r`n"), "&", "&&")
        colSub[cIdx]  := StrReplace(RTrim(colSub[cIdx],  "`r`n"), "&", "&&")
        colFull[cIdx] := StrReplace(RTrim(colFull[cIdx], "`r`n"), "&", "&&")
    }
    
    ; ==============================================================================
    ; 4. NATIVE OS TEXT MEASUREMENT (Per-Column Pixel Measurement)
    ; ==============================================================================
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    activeMonitor := 1
    
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        if (mX >= mLeft && mX <= mRight && mY >= mTop && mY <= mBottom) {
            activeMonitor := A_Index
            break
        }
    }
    
    MonitorGetWorkArea(activeMonitor, &waLeft, &waTop, &waRight, &waBottom)
    monWidth := waRight - waLeft
    monHeight := waBottom - waTop
    
    maxGuiW := Floor(monWidth * 0.98)
    maxGuiH := Floor(monHeight * 0.98) 
    
    fontSize := 36 
    colW := [0, 0, 0]
    textH := 0
    colGapPx := 28
    marginX := 16
    marginY := 8
    
    Loop {
        tempGui := Gui("-DPIScale") 
        tempGui.SetFont("s" fontSize " w700", "Consolas")
        
        maxH := 0
        Loop 3 {
            tCtrl := tempGui.Add("Text", "", colFull[A_Index])
            tCtrl.GetPos(,, &w, &h)
            colW[A_Index] := w
            if (h > maxH)
                maxH := h
        }
        tempGui.Destroy()
        
        textH := maxH
        totalTextW := colW[1] + colW[2] + colW[3] + (colGapPx * 2)
        reqGuiW := totalTextW + (marginX * 2)
        reqGuiH := textH + (marginY * 2)
        
        if ((reqGuiW <= maxGuiW) && (reqGuiH <= maxGuiH)) || (fontSize <= 8)
            break
            
        fontSize-- 
    }
    
    ; ==============================================================================
    ; 5. UI RENDERING & LOCKED 3-COLUMN OVERLAY
    ; ==============================================================================
    cheatGui := Gui("+AlwaysOnTop -Caption -Border -DPIScale", "AHK Master Cheatsheet")
    cheatGui.BackColor := "1E1E1E" 
    cheatGui.SetFont("s" fontSize " w700", "Consolas")  
    
    cheatGui.MarginX := marginX
    cheatGui.MarginY := marginY
    
    curX := marginX
    Loop 3 {
        cIdx := A_Index
        w := colW[cIdx]
        
        ; Render each column at its own locked pixel X-coordinate
        cheatGui.Add("Text", "x" curX " y" marginY " w" w " h" textH " Background1E1E1E cE0E0E0", colBase[cIdx])
        cheatGui.Add("Text", "x" curX " y" marginY " w" w " h" textH " BackgroundTrans c4DD0E1", colSub[cIdx])
        cheatGui.Add("Text", "x" curX " y" marginY " w" w " h" textH " BackgroundTrans cFFCA28", colCat[cIdx])
        
        curX += w + colGapPx
    }
    
    focusTrap := cheatGui.Add("Edit", "x0 y0 w0 h0 Background1E1E1E -Border")
    
    cheatGui.OnEvent("Escape", (*) => cheatGui.Hide())
    cheatGui.OnEvent("Close", (*) => cheatGui.Hide())
    
    cheatGui.Show("Hide AutoSize x" waLeft " y" waTop)
    cheatGui.GetPos(,, &realW, &realH)
    
    guiX := waLeft + (monWidth - realW) // 2
    guiY := waTop + (monHeight - realH) // 2
    
    cheatGui.Show("x" guiX " y" guiY)
    WinActivate("ahk_id " cheatGui.Hwnd)
    focusTrap.Focus()
}

; ==============================================================================
; 6. THE FOCUS FIX (Global Escape Override)
; ==============================================================================
#HotIf WinExist("AHK Master Cheatsheet")
~Escape:: {
    global cheatGui
    if (cheatGui) {
        cheatGui.Hide()
    }
}
#HotIf