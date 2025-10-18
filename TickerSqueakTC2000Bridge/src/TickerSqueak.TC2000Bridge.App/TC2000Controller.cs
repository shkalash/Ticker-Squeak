using System;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;

namespace TickerSqueak.TC2000Bridge.App
{
	public sealed class TC2000Controller
	{
		private readonly SettingsService _settings;

		public TC2000Controller(SettingsService settings)
		{
			_settings = settings;
		}

		public bool IsTC2000Running()
		{
			return TryGetProcess(out _);
		}

		private bool TryGetProcess(out Process proc)
		{
			proc = Process.GetProcesses()
				.FirstOrDefault(p => p.ProcessName.StartsWith("TMain", StringComparison.OrdinalIgnoreCase));
			return proc != null;
		}

		public Task<bool> LaunchIfNeededAsync()
		{
			return Task.FromResult(TryGetProcess(out _));
		}

		public async Task<bool> FocusAsync()
		{
			if (!TryGetProcess(out var proc)) return false;
			for (int i = 0; i < 30; i++)
			{
				proc.Refresh();
				var h = proc.MainWindowHandle;
				if (h == IntPtr.Zero)
				{
					h = Win32.FindMainWindowForProcess(proc.Id);
				}
				if (h != IntPtr.Zero)
				{
					Win32.ShowWindowAsync(h, Win32.SW_RESTORE);
					await Task.Delay(150);
					return Win32.BringWindowToFront(h);
				}
				await Task.Delay(100);
			}
			return false;
		}

		public async Task<bool> TypeSymbolAsync(string symbol)
		{
			if (string.IsNullOrWhiteSpace(symbol)) return false;
			if (!TryGetProcess(out var proc)) return false;
			var h = proc.MainWindowHandle;
			if (h == IntPtr.Zero) h = Win32.FindMainWindowForProcess(proc.Id);
			if (h == IntPtr.Zero) return false;

			// Click to ensure text focus, then type via Unicode
			Win32.ClickCenter(h);
			await Task.Delay(120);
			Win32.SendTextUnicode(symbol.Trim().ToUpperInvariant(), delayPerCharMs: 30);
			await Task.Delay(150);
			Win32.SendEnter();
			return true;
		}
	}
}
