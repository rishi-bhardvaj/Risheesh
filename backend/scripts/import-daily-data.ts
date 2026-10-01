import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const port = process.env.PORT || '8080';
const baseUrl = process.env.BACKEND_URL || `http://localhost:${port}`;
const apiKey = process.env.IMPORT_API_KEY;

if (!apiKey) {
  console.error('Error: IMPORT_API_KEY environment variable is not defined.');
  process.exit(1);
}

async function main() {
  const args = process.argv.slice(2);
  const dataType = args[0]; // 'jobs' or 'freelance'
  const filePath = args[1];

  if (!dataType || !filePath) {
    console.error('Usage: tsx scripts/import-daily-data.ts <jobs|freelance> <path-to-json-file>');
    process.exit(1);
  }

  const resolvedPath = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(resolvedPath)) {
    console.error(`Error: File not found at ${resolvedPath}`);
    process.exit(1);
  }

  console.log(`Reading ${dataType} import file: ${resolvedPath}...`);
  const content = fs.readFileSync(resolvedPath, 'utf8');
  let payload: any;
  try {
    payload = JSON.parse(content);
  } catch (err) {
    console.error('Error: Invalid JSON format in input file.');
    process.exit(1);
  }

  const endpoint = `${baseUrl}/api/v1/import/${dataType.toLowerCase()}`;
  console.log(`Sending POST request to ${endpoint}...`);

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const body: any = await response.json();

    if (!response.ok) {
      console.error(`Import API responded with status ${response.status}:`, JSON.stringify(body, null, 2));
      process.exit(1);
    }

    console.log('✓ Import completed successfully!');
    console.log('---------------------------------');
    console.log(`Run ID:      ${body.data.run_id}`);
    console.log(`Data Type:   ${body.data.data_type}`);
    console.log(`Source:      ${body.data.source}`);
    console.log(`Received:    ${body.data.received}`);
    console.log(`Inserted:    ${body.data.inserted}`);
    console.log(`Updated:     ${body.data.updated}`);
    console.log(`Duplicates:  ${body.data.duplicates}`);
    console.log(`Rejected:    ${body.data.rejected}`);
    if (body.data.rejection_details?.length > 0) {
      console.log('Rejections: ', body.data.rejection_details);
    }
    console.log('---------------------------------');
  } catch (err: any) {
    console.error('Network / Request Error during import:', err.message);
    process.exit(1);
  }
}

main();
