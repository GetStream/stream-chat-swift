const fs = require("fs");
const { resolve } = require("path");
const getFiles = (path) => {
	const files = fs.readdirSync(path, { withFileTypes: true });
	const [directoryName] = path.split("/").reverse();
	return {
		[directoryName]: files.map((f) =>
			f.isDirectory() ? getFiles(`${path}/${f.name}`) : `${path}/${f.name}`
		),
	};
};
(() => {
	console.log(process.argv);
	if (process.argv.length < 3) throw new Error('Missing argument "path"');
	const path = process.argv[2];
	const absolutePath = resolve(path);
	if (!fs.lstatSync(absolutePath).isDirectory())
		throw new Error("Path is not a directory");
	console.log(JSON.stringify(getFiles(absolutePath), null, 4));
})();
