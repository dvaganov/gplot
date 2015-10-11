namespace Plot {
	const int mm = 10;
	const int cm = 10*mm;
	
	public struct Point {
		public double x;
		public double y;
		public string to_string () {
			return x.to_string () + ";" + y.to_string ();
		}
		public Point.from_string (string str) {
			var array = str.split (";");
			x = double.parse (array[0]);
			y = double.parse (array[1]);
		}
	}
}
