# Overwatch adaptive borderless test: 3839x2159; topmost only while foreground.
# Press F10 to restore. Run from an ordinary PowerShell session.
$ErrorActionPreference = 'Stop'
$source = @'
using System;
using System.Runtime.InteropServices;
public static class OWAdaptiveWin {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll", EntryPoint="GetWindowLongPtrW", SetLastError=true)] public static extern IntPtr GetWindowLongPtr(IntPtr h, int index);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtrW", SetLastError=true)] public static extern IntPtr SetWindowLongPtr(IntPtr h, int index, IntPtr value);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int height, uint flags);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
}
'@
if (-not ('OWAdaptiveWin' -as [type])) { Add-Type -TypeDefinition $source }
$p = Get-Process -Name Overwatch -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { throw 'Overwatch window not found. Use Windowed or Borderless Windowed mode first.' }
$h = $p.MainWindowHandle
$oldDpi = [OWAdaptiveWin]::SetThreadDpiAwarenessContext([IntPtr](-4))
if ($oldDpi -eq [IntPtr]::Zero) { throw 'Could not set DPI context.' }
$oldStyle = [OWAdaptiveWin]::GetWindowLongPtr($h,-16)
$oldEx = [OWAdaptiveWin]::GetWindowLongPtr($h,-20)
$oldRect = New-Object OWAdaptiveWin+RECT
[OWAdaptiveWin]::GetWindowRect($h,[ref]$oldRect) | Out-Null
$top = $false
try {
    $newStyle = ($oldStyle.ToInt64() -band (-bnot 0x00CF0000L)) -bor 0x80000000L
    $newEx = $oldEx.ToInt64() -band (-bnot 0x00000301L)
    [OWAdaptiveWin]::SetWindowLongPtr($h,-16,[IntPtr]$newStyle) | Out-Null
    [OWAdaptiveWin]::SetWindowLongPtr($h,-20,[IntPtr]$newEx) | Out-Null
    # 0x0020 FRAMECHANGED; 0x0010 NOACTIVATE. Do not force topmost initially.
    $ok = [OWAdaptiveWin]::SetWindowPos($h,[IntPtr](-2),0,0,3839,2159,0x0030)
    if (-not $ok) { throw 'SetWindowPos failed.' }
    $client = New-Object OWAdaptiveWin+RECT
    [OWAdaptiveWin]::GetClientRect($h,[ref]$client) | Out-Null
    Write-Host "Physical client: $($client.Right)x$($client.Bottom)"
    Write-Host 'Alt+Tab to Overwatch. Topmost follows game focus. Press F10 anytime to restore.'
    while ([OWAdaptiveWin]::IsWindow($h)) {
        if (([OWAdaptiveWin]::GetAsyncKeyState(0x79) -band 0x8000) -ne 0) { break } # F10
        $focused = ([OWAdaptiveWin]::GetForegroundWindow() -eq $h)
        if ($focused -ne $top) {
            $insert = if ($focused) { [IntPtr](-1) } else { [IntPtr](-2) }
            # NOSIZE=1, NOMOVE=2, NOACTIVATE=0x10
            [OWAdaptiveWin]::SetWindowPos($h,$insert,0,0,0,0,0x0013) | Out-Null
            $top = $focused
        }
        Start-Sleep -Milliseconds 100
    }
}
finally {
    if ([OWAdaptiveWin]::IsWindow($h)) {
        [OWAdaptiveWin]::SetWindowLongPtr($h,-16,$oldStyle) | Out-Null
        [OWAdaptiveWin]::SetWindowLongPtr($h,-20,$oldEx) | Out-Null
        [OWAdaptiveWin]::SetWindowPos($h,[IntPtr](-2),$oldRect.Left,$oldRect.Top,($oldRect.Right-$oldRect.Left),($oldRect.Bottom-$oldRect.Top),0x0030) | Out-Null
    }
    [OWAdaptiveWin]::SetThreadDpiAwarenessContext($oldDpi) | Out-Null
    Write-Host 'Restored original window style and dimensions.'
}
