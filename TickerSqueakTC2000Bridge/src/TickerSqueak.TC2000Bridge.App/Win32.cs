using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace TickerSqueak.TC2000Bridge.App
{
	internal static class Win32
	{
		[DllImport("user32.dll")]
		public static extern bool SetForegroundWindow(IntPtr hWnd);

		[DllImport("user32.dll")]
		public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

		[DllImport("user32.dll")]
		private static extern bool IsWindowVisible(IntPtr hWnd);

		[DllImport("user32.dll")]
		private static extern IntPtr GetShellWindow();

		[DllImport("user32.dll")]
		private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

		[DllImport("user32.dll")]
		private static extern IntPtr GetForegroundWindow();

		[DllImport("kernel32.dll")]
		private static extern uint GetCurrentThreadId();

		[DllImport("user32.dll")]
		private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

		[DllImport("user32.dll")]
		private static extern bool BringWindowToTop(IntPtr hWnd);

		[DllImport("user32.dll")]
		private static extern bool SetFocus(IntPtr hWnd);

	[DllImport("user32.dll")]
	private static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

	[DllImport("user32.dll")]
	private static extern bool IsIconic(IntPtr hWnd);

	[DllImport("user32.dll")]
	private static extern bool IsZoomed(IntPtr hWnd);

	[StructLayout(LayoutKind.Sequential)]
	public struct RECT
	{
		public int Left;
		public int Top;
		public int Right;
		public int Bottom;
	}

	public const int SW_RESTORE = 9;
	public const int SW_SHOW = 5;
	public const int SW_SHOWMAXIMIZED = 3;

		[DllImport("user32.dll")]
		public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

		[StructLayout(LayoutKind.Sequential)]
		public struct INPUT
		{
			public uint type;
			public InputUnion U;
		}

		[StructLayout(LayoutKind.Explicit)]
		public struct InputUnion
		{
			[FieldOffset(0)] public KEYBDINPUT ki;
			[FieldOffset(0)] public MOUSEINPUT mi;
		}

		[StructLayout(LayoutKind.Sequential)]
		public struct KEYBDINPUT
		{
			public ushort wVk;
			public ushort wScan;
			public uint dwFlags;
			public uint time;
			public IntPtr dwExtraInfo;
		}

		[StructLayout(LayoutKind.Sequential)]
		public struct MOUSEINPUT
		{
			public int dx;
			public int dy;
			public uint mouseData;
			public uint dwFlags;
			public uint time;
			public IntPtr dwExtraInfo;
		}

		public const uint INPUT_KEYBOARD = 1;
		public const uint INPUT_MOUSE = 0;
		public const uint KEYEVENTF_KEYUP = 0x0002;

		// Mouse flags
		private const uint MOUSEEVENTF_MOVE = 0x0001;
		private const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
		private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
		private const uint MOUSEEVENTF_LEFTUP = 0x0004;

		// --- Unicode keyboard typing helpers ---
		public static void SendChar(char ch)
		{
			ushort scan = (ushort)ch;
			var down = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0, wScan = scan, dwFlags = 0x0004, time = 0, dwExtraInfo = IntPtr.Zero } } }; // KEYEVENTF_UNICODE
			var up = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0, wScan = scan, dwFlags = 0x0004 | KEYEVENTF_KEYUP, time = 0, dwExtraInfo = IntPtr.Zero } } };
			SendInput(2, new[] { down, up }, Marshal.SizeOf<INPUT>());
		}

		public static void SendTextUnicode(string text, int delayPerCharMs = 0)
		{
			foreach (var ch in text)
			{
				SendChar(ch);
				if (delayPerCharMs > 0) Thread.Sleep(delayPerCharMs);
			}
		}

		public static void SendEnter()
		{
			var down = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0x0D, wScan = 0, dwFlags = 0, time = 0, dwExtraInfo = IntPtr.Zero } } };
			var up = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0x0D, wScan = 0, dwFlags = KEYEVENTF_KEYUP, time = 0, dwExtraInfo = IntPtr.Zero } } };
			SendInput(2, new[] { down, up }, Marshal.SizeOf<INPUT>());
		}

	// --- Window discovery and focusing ---
	public static IntPtr FindMainWindowForProcess(int processId)
	{
		IntPtr shellWindow = GetShellWindow();
		IntPtr best = IntPtr.Zero;
		EnumWindowsProc callback = (hWnd, lParam) =>
		{
			if (hWnd == shellWindow) return true;
			if (!IsWindowVisible(hWnd)) return true;
			GetWindowThreadProcessId(hWnd, out uint pid);
			if (pid != (uint)processId) return true;
			best = hWnd;
			return false;
		};
		EnumWindows(callback, IntPtr.Zero);
		return best;
	}

	/// <summary>
	/// Gets the appropriate ShowWindow command based on current window state.
	/// This preserves maximized state instead of forcing restore.
	/// </summary>
	public static int GetShowCommandForWindow(IntPtr hWnd)
	{
		if (IsIconic(hWnd))
		{
			// Window is minimized - check if it was maximized before minimizing
			// We'll use SW_RESTORE which will restore to previous state
			return SW_RESTORE;
		}
		else if (IsZoomed(hWnd))
		{
			// Window is maximized - keep it maximized
			return SW_SHOWMAXIMIZED;
		}
		else
		{
			// Window is normal - just show it
			return SW_SHOW;
		}
	}

		public static bool BringWindowToFront(IntPtr hWnd)
		{
			var foreground = GetForegroundWindow();
			uint thisThread = GetCurrentThreadId();
			uint foreThread = GetWindowThreadProcessId(foreground, out _);
			bool attached = false;
			try
			{
				if (thisThread != foreThread)
				{
					attached = AttachThreadInput(thisThread, foreThread, true);
				}
				BringWindowToTop(hWnd);
				SetForegroundWindow(hWnd);
				SetFocus(hWnd);
				return true;
			}
			finally
			{
				if (attached)
				{
					AttachThreadInput(thisThread, foreThread, false);
				}
			}
		}

		public static void ClickCenter(IntPtr hWnd)
		{
			if (!GetWindowRect(hWnd, out var r)) return;
			int cx = (r.Left + r.Right) / 2;
			int cy = (r.Top + r.Bottom) / 2;
			ClickScreenPoint(cx, cy);
		}

		private static void ClickScreenPoint(int x, int y)
		{
			int screenW = GetSystemMetrics(0);
			int screenH = GetSystemMetrics(1);
			int absX = (int)(x * 65535L / Math.Max(screenW - 1, 1));
			int absY = (int)(y * 65535L / Math.Max(screenH - 1, 1));
			var move = new INPUT { type = INPUT_MOUSE, U = new InputUnion { mi = new MOUSEINPUT { dx = absX, dy = absY, mouseData = 0, dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE, time = 0, dwExtraInfo = IntPtr.Zero } } };
			var down = new INPUT { type = INPUT_MOUSE, U = new InputUnion { mi = new MOUSEINPUT { dx = absX, dy = absY, mouseData = 0, dwFlags = MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_ABSOLUTE, time = 0, dwExtraInfo = IntPtr.Zero } } };
			var up = new INPUT { type = INPUT_MOUSE, U = new InputUnion { mi = new MOUSEINPUT { dx = absX, dy = absY, mouseData = 0, dwFlags = MOUSEEVENTF_LEFTUP | MOUSEEVENTF_ABSOLUTE, time = 0, dwExtraInfo = IntPtr.Zero } } };
			SendInput(1, new[] { move }, Marshal.SizeOf<INPUT>());
			SendInput(1, new[] { down }, Marshal.SizeOf<INPUT>());
			SendInput(1, new[] { up }, Marshal.SizeOf<INPUT>());
		}

		[DllImport("user32.dll")]
		private static extern int GetSystemMetrics(int nIndex);

		private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

		[DllImport("user32.dll")]
		private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
	}
}
