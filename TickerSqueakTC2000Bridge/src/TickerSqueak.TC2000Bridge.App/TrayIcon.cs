using System;
using System.Drawing;
using System.Windows.Forms;

namespace TickerSqueak.TC2000Bridge.App
{
	public sealed class TrayIcon : IDisposable
	{
		private readonly NotifyIcon _notifyIcon;
		private readonly ContextMenuStrip _menu;
		private readonly ToolStripMenuItem _openItem;
		private readonly ToolStripMenuItem _quitItem;

		public event EventHandler? OpenRequested;
		public event EventHandler? QuitRequested;

		public TrayIcon()
		{
			_menu = new ContextMenuStrip();
			_openItem = new ToolStripMenuItem("Open");
			_quitItem = new ToolStripMenuItem("Quit");
			_menu.Items.AddRange(new ToolStripItem[] { _openItem, _quitItem });

			Icon icon = SystemIcons.Application;
			try
			{
				var exeIcon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
				if (exeIcon != null) icon = exeIcon;
			}
			catch { }

			_notifyIcon = new NotifyIcon
			{
				Visible = true,
				ContextMenuStrip = _menu,
				Text = "TC2000 Bridge",
				Icon = icon
			};

			_notifyIcon.MouseClick += (s, e) =>
			{
				if (e.Button == MouseButtons.Left)
				{
					OpenRequested?.Invoke(this, EventArgs.Empty);
				}
			};
			_openItem.Click += (s, e) => OpenRequested?.Invoke(this, EventArgs.Empty);
			_quitItem.Click += (s, e) => QuitRequested?.Invoke(this, EventArgs.Empty);
		}

		public void SetTooltip(string text)
		{
			_notifyIcon.Text = string.IsNullOrWhiteSpace(text) ? "TC2000 Bridge" : text;
		}

		public void Dispose()
		{
			_notifyIcon.Visible = false;
			_notifyIcon.Dispose();
			_menu.Dispose();
		}
	}
}
