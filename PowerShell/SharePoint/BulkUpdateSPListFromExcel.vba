Private Sub Workbook_Open()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(1)
    Dim Src(1) As Variant
    Src(0) = "http://mysharepointsite.com/sites/SITENAME" & "/_vti_bin"
    Src(1) = "B5A24333-4BC6-4223-9956-B8CEEB194717"
    If ws.ListObjects.Count = 0 Then
        ws.ListObjects.Add xlSrcExternal, Src, True, xlYes, ws.Range("A1")
    Else
        Set objListObj = ws.ListObjects(1)
    objListObj.Refresh
    End If
End Sub

Sub Update()
    Dim ws As Worksheet
    Dim objListObj As ListObject
    Set ws = ActiveWorkbook.Worksheets(1)
    Set objListObj = ws.ListObjects(1)
    objListObj.UpdateChanges xlListConflictDialog
End Sub

