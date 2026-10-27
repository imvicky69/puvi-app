const fs = require('fs');
const path = require('path');

const data = JSON.parse(fs.readFileSync(path.resolve(__dirname, '..', 'old_app_data.json'), 'utf8'));
const list = data.timeline || [];

console.log('Total timeline items:', list.length);

// Chronological sort
const sorted = [...list].sort((a, b) => new Date(a.date) - new Date(b.date));

sorted.forEach((item, i) => {
  console.log(`\n================== [${i + 1}] ==================`);
  console.log(`ID:           ${item._id}`);
  console.log(`Date:         ${item.date}`);
  console.log(`Title:        ${item.title}`);
  console.log(`Note:         ${item.note ? JSON.stringify(item.note) : '(empty)'}`);
  console.log(`Location:     ${item.location !== undefined ? JSON.stringify(item.location) : 'undefined'}`);
  console.log(`Coordinates:  ${JSON.stringify(item.coordinates)}`);
  console.log(`ImageUrl:     ${item.imageUrl ? item.imageUrl.substring(0, 75) + '...' : '(none)'}`);
  console.log(`CreatedAt:    ${item.createdAt}`);
});
