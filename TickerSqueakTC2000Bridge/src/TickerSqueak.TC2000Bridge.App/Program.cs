using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

namespace TickerSqueak.TC2000Bridge.App
{
	internal static class Program
	{
		[DllImport("user32.dll")]
		private static extern bool SetForegroundWindow(IntPtr hWnd);

		private const string MutexName = "Global_TickerSqueak_TC2000Bridge_SingleInstance";

		[STAThread]
		private static void Main()
		{
			bool created;
			using var mutex = new Mutex(initiallyOwned: true, name: MutexName, createdNew: out created);
			if (!created)
			{
				// Another instance exists; try to bring its window to front
				var procs = System.Diagnostics.Process.GetProcessesByName("TickerSqueak.TC2000Bridge");
				foreach (var p in procs)
				{
					if (p.MainWindowHandle != IntPtr.Zero)
					{
						SetForegroundWindow(p.MainWindowHandle);
						break;
					}
				}
				return;
			}

			Application.EnableVisualStyles();
			Application.SetCompatibleTextRenderingDefault(false);
			Application.Run(new MainForm());
		}
	}
}
