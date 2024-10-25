// get file name as arg from command line and return the count of the words in the file
// if file not found return -1
// if file is empty return 0
// if file is not a text file return -2

import { readFileSync } from 'fs';
import { join, extname } from 'path';
try {
	const filePath = join(process.cwd(), process.argv[2]);
	if (extname(filePath) !== '.txt') console.log(-2);
	else {
		console.log(
			readFileSync(filePath, 'utf-8')
				.split(/(\s+)/)
				.filter((e) => e.trim().length > 0).length
		);
	}
} catch (err) {
	console.log(err);
}
