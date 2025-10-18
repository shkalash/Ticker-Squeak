namespace TickerSqueak.TC2000Bridge.App
{
	partial class MainForm
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            lblPort = new Label();
            numPort = new NumericUpDown();
            lblSymbol = new Label();
            txtSymbol = new TextBox();
            btnStart = new Button();
            btnStop = new Button();
            btnSave = new Button();
            btnTest = new Button();
            btnTestEndpoint = new Button();
            btnHealth = new Button();
            lblStatus = new Label();
            chkStartMin = new CheckBox();
            chkLaunchAtStartup = new CheckBox();
            ((System.ComponentModel.ISupportInitialize)numPort).BeginInit();
            SuspendLayout();
            // 
            // lblPort
            // 
            lblPort.AutoSize = true;
            lblPort.Location = new Point(22, 32);
            lblPort.Margin = new Padding(6, 0, 6, 0);
            lblPort.Name = "lblPort";
            lblPort.Size = new Size(56, 32);
            lblPort.TabIndex = 0;
            lblPort.Text = "Port";
            // 
            // numPort
            // 
            numPort.Location = new Point(186, 26);
            numPort.Margin = new Padding(6);
            numPort.Maximum = new decimal(new int[] { 65535, 0, 0, 0 });
            numPort.Minimum = new decimal(new int[] { 1024, 0, 0, 0 });
            numPort.Name = "numPort";
            numPort.Size = new Size(223, 39);
            numPort.TabIndex = 1;
            numPort.Value = new decimal(new int[] { 5055, 0, 0, 0 });
            // 
            // lblSymbol
            // 
            lblSymbol.AutoSize = true;
            lblSymbol.Location = new Point(22, 107);
            lblSymbol.Margin = new Padding(6, 0, 6, 0);
            lblSymbol.Name = "lblSymbol";
            lblSymbol.Size = new Size(142, 32);
            lblSymbol.TabIndex = 5;
            lblSymbol.Text = "Test Symbol";
            // 
            // txtSymbol
            // 
            txtSymbol.Location = new Point(186, 100);
            txtSymbol.Margin = new Padding(6);
            txtSymbol.Name = "txtSymbol";
            txtSymbol.Size = new Size(219, 39);
            txtSymbol.TabIndex = 6;
            txtSymbol.Text = "AAPL";
            // 
            // btnStart
            // 
            btnStart.Location = new Point(22, 259);
            btnStart.Margin = new Padding(6);
            btnStart.Name = "btnStart";
            btnStart.Size = new Size(139, 53);
            btnStart.TabIndex = 7;
            btnStart.Text = "Start";
            btnStart.UseVisualStyleBackColor = true;
            btnStart.Click += btnStart_Click;
            // 
            // btnStop
            // 
            btnStop.Location = new Point(173, 259);
            btnStop.Margin = new Padding(6);
            btnStop.Name = "btnStop";
            btnStop.Size = new Size(139, 53);
            btnStop.TabIndex = 8;
            btnStop.Text = "Stop";
            btnStop.UseVisualStyleBackColor = true;
            btnStop.Click += btnStop_Click;
            // 
            // btnSave
            // 
            btnSave.Location = new Point(438, 18);
            btnSave.Margin = new Padding(6);
            btnSave.Name = "btnSave";
            btnSave.Size = new Size(139, 53);
            btnSave.TabIndex = 9;
            btnSave.Text = "Save";
            btnSave.UseVisualStyleBackColor = true;
            btnSave.Click += btnSave_Click;
            // 
            // btnTest
            // 
            btnTest.Location = new Point(22, 181);
            btnTest.Margin = new Padding(6);
            btnTest.Name = "btnTest";
            btnTest.Size = new Size(182, 53);
            btnTest.TabIndex = 10;
            btnTest.Text = "Test Locally";
            btnTest.UseVisualStyleBackColor = true;
            btnTest.Click += btnTest_Click;
            // 
            // btnTestEndpoint
            // 
            btnTestEndpoint.Location = new Point(216, 181);
            btnTestEndpoint.Margin = new Padding(6);
            btnTestEndpoint.Name = "btnTestEndpoint";
            btnTestEndpoint.Size = new Size(205, 53);
            btnTestEndpoint.TabIndex = 11;
            btnTestEndpoint.Text = "Test Endpoint";
            btnTestEndpoint.UseVisualStyleBackColor = true;
            btnTestEndpoint.Click += btnTestEndpoint_Click;
            // 
            // btnHealth
            // 
            btnHealth.Location = new Point(433, 181);
            btnHealth.Margin = new Padding(6);
            btnHealth.Name = "btnHealth";
            btnHealth.Size = new Size(204, 53);
            btnHealth.TabIndex = 12;
            btnHealth.Text = "Open Health";
            btnHealth.UseVisualStyleBackColor = true;
            btnHealth.Click += btnHealth_Click;
            // 
            // lblStatus
            // 
            lblStatus.AutoSize = true;
            lblStatus.Location = new Point(22, 336);
            lblStatus.Margin = new Padding(6, 0, 6, 0);
            lblStatus.Name = "lblStatus";
            lblStatus.Size = new Size(78, 32);
            lblStatus.TabIndex = 13;
            lblStatus.Text = "Status";
            // 
            // chkStartMin
            // 
            chkStartMin.AutoSize = true;
            chkStartMin.Location = new Point(284, 389);
            chkStartMin.Margin = new Padding(6);
            chkStartMin.Name = "chkStartMin";
            chkStartMin.Size = new Size(214, 36);
            chkStartMin.TabIndex = 14;
            chkStartMin.Text = "Start Minimized";
            chkStartMin.UseVisualStyleBackColor = true;
            // 
            // chkLaunchAtStartup
            // 
            chkLaunchAtStartup.AutoSize = true;
            chkLaunchAtStartup.Location = new Point(22, 389);
            chkLaunchAtStartup.Margin = new Padding(6);
            chkLaunchAtStartup.Name = "chkLaunchAtStartup";
            chkLaunchAtStartup.Size = new Size(230, 36);
            chkLaunchAtStartup.TabIndex = 13;
            chkLaunchAtStartup.Text = "Launch at startup";
            chkLaunchAtStartup.UseVisualStyleBackColor = true;
            // 
            // MainForm
            // 
            AutoScaleDimensions = new SizeF(13F, 32F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(660, 493);
            Controls.Add(chkLaunchAtStartup);
            Controls.Add(chkStartMin);
            Controls.Add(lblStatus);
            Controls.Add(btnHealth);
            Controls.Add(btnTestEndpoint);
            Controls.Add(btnTest);
            Controls.Add(btnSave);
            Controls.Add(btnStop);
            Controls.Add(btnStart);
            Controls.Add(txtSymbol);
            Controls.Add(lblSymbol);
            Controls.Add(numPort);
            Controls.Add(lblPort);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            Margin = new Padding(6);
            MaximizeBox = false;
            Name = "MainForm";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "TC2000 Bridge";
            FormClosing += MainForm_FormClosing;
            Resize += MainForm_Resize;
            ((System.ComponentModel.ISupportInitialize)numPort).EndInit();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private System.Windows.Forms.Label lblPort;
		private System.Windows.Forms.NumericUpDown numPort;
		private System.Windows.Forms.Label lblSymbol;
		private System.Windows.Forms.TextBox txtSymbol;
		private System.Windows.Forms.Button btnStart;
		private System.Windows.Forms.Button btnStop;
		private System.Windows.Forms.Button btnSave;
		private System.Windows.Forms.Button btnTest;
		private System.Windows.Forms.Button btnTestEndpoint;
		private System.Windows.Forms.Button btnHealth;
		private System.Windows.Forms.Label lblStatus;
		private System.Windows.Forms.CheckBox chkStartMin;
		private System.Windows.Forms.CheckBox chkLaunchAtStartup;
	}
}
