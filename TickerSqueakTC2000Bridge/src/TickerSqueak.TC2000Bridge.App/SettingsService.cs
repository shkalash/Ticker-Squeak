using System;
using System.IO;
using System.Text.Json;

namespace TickerSqueak.TC2000Bridge.App
{
	public sealed class SettingsService
	{
		private readonly string _configDir;
		private readonly string _configPath;

		public SettingsService()
		{
			_configDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "TickerSqueak.TC2000Bridge");
			_configPath = Path.Combine(_configDir, "config.json");
		}

		public AppConfig Load()
		{
			try
			{
				if (!File.Exists(_configPath))
				{
					return new AppConfig();
				}
				var json = File.ReadAllText(_configPath);
				var cfg = JsonSerializer.Deserialize<AppConfig>(json);
				return cfg ?? new AppConfig();
			}
			catch
			{
				return new AppConfig();
			}
		}

		public void Save(AppConfig config)
		{
			Directory.CreateDirectory(_configDir);
			var json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
			File.WriteAllText(_configPath, json);
		}
	}
}
