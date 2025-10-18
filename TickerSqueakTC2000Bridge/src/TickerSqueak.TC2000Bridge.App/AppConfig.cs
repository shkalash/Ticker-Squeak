using System.Text.Json.Serialization;

namespace TickerSqueak.TC2000Bridge.App
{
	public sealed class AppConfig
	{
		[JsonPropertyName("port")]
		public int Port { get; set; } = 5055;

		[JsonPropertyName("startMinimized")]
		public bool StartMinimized { get; set; } = false;

		[JsonPropertyName("launchAtStartup")]
		public bool LaunchAtStartup { get; set; } = false;
	}
}
