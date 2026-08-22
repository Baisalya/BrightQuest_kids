import json, pathlib, re
ROOT=pathlib.Path(__file__).resolve().parents[2]

def item(q, answer, choices, explanation, hint, kind='text'):
    assert answer in choices
    return dict(q=q, answer=answer, choices=choices, explanation=explanation, hint=hint, kind=kind)

SPECS={
3:{
'c3_math_place_value_999': dict(teach='A digit’s value depends on its place. Hundreds, tens and ones can be composed, decomposed and compared.', items=[
 item('In 472, what value does the digit 7 represent?',70,[7,70,700,472],'The 7 is in the tens place, so its value is 70.','Name the hundreds, tens and ones places.','number'),
 item('Which number is 300 + 40 + 6?',346,[346,364,436,306],'300 + 40 + 6 is 346.','Combine the hundreds, tens and ones.','number'),
 item('Which number is greater: 598 or 589?',598,[589,598,588,599],'598 is greater because both have 5 hundreds, but 9 tens is greater than 8 tens.','Compare hundreds first, then tens.','number'),
 item('A shelf has 625 books and another has 652. Which shelf count is larger?',652,[625,652,622,655],'652 is larger than 625 because 6 hundreds are equal and 5 tens is greater than 2 tens.','Compare from the greatest place value.','number'),
]),
'c3_math_money_bills': dict(teach='Use rupees as amounts: add costs to find a total, subtract spending to find change, and compare amounts by value.', items=[
 item('A notebook costs ₹35 and a pencil costs ₹15. What is the total cost?',50,[40,45,50,55],'₹35 + ₹15 = ₹50.','Add the two costs.','number'),
 item('You have ₹100 and spend ₹64. How many rupees remain?',36,[26,34,36,46],'₹100 − ₹64 = ₹36, so ₹36 remains.','Subtract the amount spent from ₹100.','number'),
 item('Which amount is greater: ₹78 or ₹87?',87,[78,80,87,97],'₹87 is greater than ₹78 because it has 8 tens instead of 7 tens.','Compare the tens digits.','number'),
 item('Two juice boxes cost ₹24 each. What is the total cost?',48,[36,44,48,58],'₹24 + ₹24 = ₹48.','Add two equal costs.','number'),
]),
'c3_math_measurement': dict(teach='Choose a sensible unit before measuring. Centimetres suit small lengths, metres suit larger lengths, grams/kilograms suit mass, and millilitres/litres suit capacity.', items=[
 item('Which unit is most suitable for the length of a pencil?','centimetres',['centimetres','kilometres','litres','kilograms'],'A pencil is a small length, so centimetres are suitable.','Ask whether you are measuring length, mass or capacity.'),
 item('How many centimetres are in 1 metre?',100,[10,50,100,1000],'1 metre equals 100 centimetres.','Think of a metre ruler.','number'),
 item('Which is heavier: 2 kg of rice or 750 g of sugar?','2 kg of rice',['2 kg of rice','750 g of sugar','They are equal','Cannot be compared'],'2 kg is 2000 g, so 2 kg of rice is heavier than 750 g of sugar.','Convert kilograms to grams if it helps.'),
 item('A jug holds 1 litre. How many 500 mL cups fill it?',2,[1,2,5,10],'1 litre is 1000 mL, and two 500 mL cups make 1000 mL.','Two equal 500 mL parts make one litre.','number'),
]),
'c3_math_time_calendar': dict(teach='Read clock times by hours and minutes, and use day/date order to reason about calendars.', items=[
 item('What time is 30 minutes after 3:00?','3:30',['3:15','3:30','4:00','4:30'],'Thirty minutes after 3:00 is 3:30.','Move half an hour forward.'),
 item('How many days are in one week?',7,[5,6,7,8],'A week has 7 days.','Count Monday through Sunday.','number'),
 item('If today is Monday, what day is two days later?','Wednesday',['Tuesday','Wednesday','Thursday','Sunday'],'One day after Monday is Tuesday; two days after is Wednesday.','Move forward one day at a time.'),
 item('School begins at 9:00 and lunch is at 12:00. How much time passes?','3 hours',['2 hours','3 hours','4 hours','30 minutes'],'From 9:00 to 12:00 is 3 hours.','Count the whole hours: 9 to 10, 10 to 11, 11 to 12.'),
]),
'c3_math_shapes_patterns_data': dict(teach='Look at defining shape features, state the rule in a pattern, and read data labels before comparing values.', items=[
 item('Which 2D shape has exactly 3 sides?','Triangle',['Triangle','Square','Circle','Rectangle'],'A triangle has exactly 3 straight sides.','Count the sides.'),
 item('Continue the pattern: 2, 4, 6, 8, __.',10,[9,10,11,12],'The rule is add 2, so the next number after 8 is 10.','Say how each number changes.','number'),
 item('A table shows Red: 4, Blue: 7, Green: 5. Which colour has the greatest count?','Blue',['Red','Blue','Green','They are equal'],'Blue has the greatest count because 7 is greater than 5 and 4.','Compare the three numbers.'),
 item('Which 3D shape has 6 equal square faces?','Cube',['Cube','Sphere','Cone','Cylinder'],'A cube has 6 equal square faces.','Think of a standard dice shape.'),
]),
'c3_eng_literal_comprehension': dict(teach='For a literal question, find the sentence that directly states the answer instead of guessing beyond the text.', items=[
 item('Mira packed a blue umbrella because dark clouds filled the sky. What colour was the umbrella?','Blue',['Blue','Red','Green','Yellow'],'The text directly says “a blue umbrella”, so the answer is Blue.','Find the words that describe the umbrella.'),
 item('Ravi planted three bean seeds on Saturday. What did Ravi plant?','Bean seeds',['Bean seeds','Tomato plants','A tree','Flowers'],'The sentence directly states that Ravi planted bean seeds.','Look for the words after “planted”.'),
 item('The bus arrived at eight o’clock, and Meena boarded with her brother. When did the bus arrive?','Eight o’clock',['Seven o’clock','Eight o’clock','Nine o’clock','At noon'],'The text directly gives the arrival time as eight o’clock.','Find the time named in the sentence.'),
 item('Asha put the library book on the top shelf before dinner. Where did she put the book?','On the top shelf',['On the top shelf','Under the bed','In her bag','On the table'],'The text directly says the book was put on the top shelf.','Find the place named after “put”.'),
]),
'c3_eng_main_idea_details': dict(teach='The main idea tells what a short text is mostly about. Supporting details give specific information that helps prove that main idea.', items=[
 item('Tara waters the balcony plants every morning. She removes dry leaves and checks the soil. What is the main idea?','Tara cares for her balcony plants',['Tara cares for her balcony plants','Tara buys a new bicycle','The balcony is closed','Morning is always rainy'],'Both sentences describe how Tara cares for the plants.','Ask what both sentences are mostly about.'),
 item('A school garden has tomatoes, beans and spinach. Students take turns watering them. Which detail supports the idea that students care for the garden?','Students take turns watering the plants',['The garden has tomatoes','Students take turns watering the plants','Spinach is green','The school has classrooms'],'Taking turns watering is a direct detail showing care for the garden.','Choose the detail that shows an action of care.'),
 item('Rohan packed a bottle, a cap and a map for the walk. He checked his bag before leaving. What is this text mainly about?','Rohan getting ready for a walk',['Rohan getting ready for a walk','Rohan cooking dinner','A lost map','Buying a school bag'],'The details all show Rohan preparing for a walk.','Group the details under one big idea.'),
 item('The puppy was cold, so Nia brought a towel and moved its bed away from the open door. Which detail best supports that Nia helped the puppy?','She moved its bed away from the open door',['The puppy was cold','Nia saw a door','She moved its bed away from the open door','The towel was blue'],'Moving the bed away from the open door is an action that helps the cold puppy.','Choose an action Nia took to help.'),
]),
'c3_eng_vocab_context': dict(teach='Use nearby clues to infer an unfamiliar word. Then replace the word with your meaning and check that the sentence still makes sense.', items=[
 item('The kitten was timid; it hid behind the chair when visitors came. What does timid mean here?','shy',['shy','noisy','hungry','fast'],'Hiding from visitors is a clue that timid means shy.','Use the action after the semicolon as a clue.'),
 item('The enormous pumpkin was much bigger than all the others. What does enormous mean?','very large',['very large','very small','empty','soft'],'“Much bigger than all the others” shows that enormous means very large.','Look for the comparison clue.'),
 item('After the long race, Kabir was exhausted and sat down to rest. What does exhausted mean?','very tired',['very tired','very excited','very clean','very early'],'Needing to sit and rest after a long race shows that exhausted means very tired.','What feeling would make someone need rest?'),
 item('Mina carried the fragile glass carefully so it would not break. What does fragile mean?','easy to break',['easy to break','very heavy','full of water','brightly coloured'],'The clue “so it would not break” shows that fragile means easy to break.','Use the reason she carried it carefully.'),
]),
'c3_eng_punctuation_capitals': dict(teach='Begin a sentence and proper names with capital letters, and finish a statement, question or exclamation with the matching end mark.', items=[
 item('Which sentence is written correctly?','Rina plays outside.',['rina plays outside.','Rina plays outside.','Rina plays outside?','rina Plays outside.'],'“Rina plays outside.” begins with a capital letter and ends with a full stop.','Check the first letter and the end mark.'),
 item('Which sentence is a correctly written question?','Where is my pencil?',['Where is my pencil.','where is my pencil?','Where is my pencil?','Where is my pencil!'],'A question begins with a capital letter and ends with a question mark: “Where is my pencil?”','Questions end with a question mark.'),
 item('Which sentence uses a capital for the name correctly?','Aman lives in Pune.',['aman lives in Pune.','Aman lives in pune.','Aman lives in Pune.','aman lives in pune.'],'Aman and Pune are names, so both begin with capital letters.','Look for the person and place names.'),
 item('Which sentence is punctuated correctly?','What a wonderful surprise!',['What a wonderful surprise.','what a wonderful surprise!','What a wonderful surprise!','What a wonderful surprise?'],'An excited exclamation can end with an exclamation mark, and the sentence begins with a capital letter.','Check the capital and the exclamation mark.'),
]),
'c3_eng_short_composition': dict(teach='A short composition needs connected ideas in a sensible order. Plan a clear beginning, middle and ending, then reread to check that the ideas stay connected.', mastery=False, items=[
 item('Which is the best beginning for a short story about finding a lost puppy?','One morning, I heard a soft bark near the gate.',['One morning, I heard a soft bark near the gate.','Puppies are animals.','The end.','Blue is my favourite colour.'],'The first sentence introduces the event and gives the reader a clear starting point.','Choose a sentence that starts the event.'),
 item('After “I gave the puppy some water,” which sentence connects best?','Then I checked its collar for a name.',['Then I checked its collar for a name.','Yesterday is before today.','My shoes are black.','The moon is far away.'],'Checking the collar logically continues the action of helping the lost puppy.','Choose the sentence that continues the same event.'),
 item('Which is the clearest ending to a story about returning the puppy home?','At last, the puppy was safely back with its family.',['At last, the puppy was safely back with its family.','A gate can be made of metal.','I like mangoes.','The puppy was found at the beginning.'],'This sentence closes the event and tells how it ended.','Choose a sentence that completes the event.'),
 item('Which three-sentence sequence is most connected?','I planted a seed. I watered it each day. Soon a small shoot appeared.',['I planted a seed. I watered it each day. Soon a small shoot appeared.','I planted a seed. Trains are fast. My bag is blue.','Soon a shoot appeared. I had not planted anything. The seed was never watered.','I watered a seed. The story ends before it begins. I planted it later.'],'The three sentences stay on one topic and follow a sensible beginning-to-ending order.','Check whether every sentence belongs to the same event and follows logically.'),
]),
'c3_evs_family_community': dict(teach='Families and communities work through shared roles, care and respectful cooperation. People can contribute in different ways.', items=[
 item('Someone at home is carrying several grocery bags. Which action is helpful and respectful?','Offer to carry a bag',['Offer to carry a bag','Hide the bags','Block the doorway','Make the load heavier'],'Offering suitable help is a respectful way to share responsibility.','Choose an action that reduces the work safely.'),
 item('Why do communities have people doing different kinds of work?','Different services help meet different needs',['Different services help meet different needs','Everyone must do the same job','Only one job is useful','Jobs stop people helping each other'],'Different roles and services help a community meet many needs.','Think about why a clinic, shop and bus service do different things.'),
 item('A neighbour needs help carrying a light parcel to the door. What is a respectful choice?','Offer help and listen to what they need',['Offer help and listen to what they need','Take the parcel without asking','Ignore them on purpose','Tell them they cannot do anything'],'Offering help while listening respects the other person’s choice and dignity.','Helpful participation includes asking and listening.'),
 item('Which example shows community cooperation?','Residents report a broken streetlight so it can be repaired',['Residents report a broken streetlight so it can be repaired','People damage a public bench','Everyone wastes water','No one follows safety signs'],'Reporting a shared problem so the responsible service can repair it is community cooperation.','Choose the action that helps a shared place.'),
]),
'c3_evs_food_water_shelter': dict(teach='Food, water and shelter meet basic needs. Responsible choices avoid waste and protect shared resources.', items=[
 item('Turning off the tap while brushing mainly helps save what resource?','Water',['Water','Sunlight','Soil','Air'],'Turning off an unused tap reduces water waste.','Think about what is flowing from the tap.'),
 item('Food mainly helps our bodies by providing what?','Energy and nutrients',['Energy and nutrients','Plastic','Road signs','Electric wires'],'Food provides energy and nutrients that bodies need to grow and function.','Think about why our bodies need food.'),
 item('What is a main job of a roof on a home?','Protect people from weather',['Protect people from weather','Make drinking water salty','Grow roots','Move traffic'],'A roof helps shelter people from sun, rain and other weather.','Think about the purpose of shelter.'),
 item('Which choice uses water responsibly?','Close a dripping tap and tell an adult',['Close a dripping tap and tell an adult','Leave a tap running for no reason','Throw clean water away','Play with a leaking pipe'],'Closing a dripping tap and reporting the leak helps prevent water waste.','Choose the action that prevents unnecessary loss of water.'),
]),
},
4:{
'c4_math_place_value_10000': dict(teach='Read multi-digit numbers from the greatest place value. Decompose them into thousands, hundreds, tens and ones before comparing.', items=[
 item('In 5,482, what value does the digit 5 represent?',5000,[5,50,500,5000],'The 5 is in the thousands place, so its value is 5,000.','Name the place of the digit 5.','number'),
 item('Which number is 7,000 + 300 + 20 + 9?',7329,[7029,7309,7329,7392],'7,000 + 300 + 20 + 9 = 7,329.','Combine thousands, hundreds, tens and ones.','number'),
 item('Which number is greater: 8,905 or 8,950?',8950,[8905,8950,8850,8995],'Both have 8 thousands and 9 hundreds; 5 tens is greater than 0 tens, so 8,950 is greater.','Compare one place at a time from the left.','number'),
 item('A stadium count is 9,408 and another is 9,480. Which count is larger?',9480,[9408,9480,9084,9840],'9,480 is larger because after 9 thousands and 4 hundreds, it has 8 tens instead of 0 tens.','Compare the first place where the digits differ.','number'),
]),
'c4_math_measure_perimeter': dict(teach='Perimeter is the distance around a shape. Use consistent units and add every side length once.', items=[
 item('A rectangle is 6 cm long and 4 cm wide. What is its perimeter in centimetres?',20,[10,20,24,40],'Perimeter = 6 + 4 + 6 + 4 = 20 cm.','Add all four side lengths.','number'),
 item('How many centimetres are in 2 metres?',200,[20,100,200,2000],'1 metre is 100 cm, so 2 metres is 200 cm.','Multiply 100 cm by 2.','number'),
 item('A square has sides of 5 cm. What is its perimeter?',20,[10,15,20,25],'A square has four equal sides, so 5 + 5 + 5 + 5 = 20 cm.','Four equal sides means four groups of 5.','number'),
 item('A triangular garden has sides 4 m, 5 m and 6 m. What is its perimeter?',15,[9,11,15,24],'The perimeter is 4 + 5 + 6 = 15 m.','Add each side once.','number'),
]),
'c4_math_time_money': dict(teach='For elapsed time, move forward in hours and minutes. For money, add costs or subtract from the amount paid and keep rupees consistent.', items=[
 item('How many minutes pass from 2:15 to 3:00?',45,[30,45,60,75],'From 2:15 to 3:00 is 45 minutes.','Count forward to the next hour.','number'),
 item('You pay ₹200 for an item costing ₹135. How much change should you get?',65,[55,65,75,85],'₹200 − ₹135 = ₹65.','Subtract the cost from the amount paid.','number'),
 item('What time is 1 hour 30 minutes after 10:45?','12:15',['11:15','11:45','12:15','12:45'],'One hour after 10:45 is 11:45; 30 more minutes gives 12:15.','Add the hour first, then the minutes.'),
 item('Three tickets cost ₹45 each. What is the total cost?',135,[90,120,135,145],'₹45 × 3 = ₹135.','Add 45 three times or multiply 45 by 3.','number'),
]),
'c4_math_geometry_symmetry': dict(teach='Classify shapes by defining properties. A line of symmetry divides a shape into matching mirror halves.', items=[
 item('Which shape always has 4 equal sides and 4 right angles?','Square',['Square','Rectangle','Triangle','Circle'],'A square has four equal sides and four right angles.','Check both side lengths and angles.'),
 item('How many lines of symmetry does a non-square rectangle have?',2,[0,1,2,4],'A non-square rectangle has 2 lines of symmetry: one vertical and one horizontal through its centre.','Imagine folding the rectangle into matching halves.','number'),
 item('Which angle is exactly a right angle?','90°',['45°','60°','90°','120°'],'A right angle measures 90°.','Think of the corner of a square.'),
 item('A shape matches itself after folding along one line. What does that line show?','Line symmetry',['Line symmetry','Perimeter','Mass','Volume'],'A fold that makes matching halves shows a line of symmetry.','Look for two mirror halves.'),
]),
'c4_math_data_patterns': dict(teach='Read the labels and values in a table or chart before comparing. For patterns, state the rule and apply it consistently.', items=[
 item('Continue the pattern: 5, 10, 15, 20, __.',25,[21,24,25,30],'The rule is add 5, so the next number is 25.','Find the repeated change.','number'),
 item('A table shows Apples: 8, Bananas: 5, Oranges: 11. Which fruit has the greatest count?','Oranges',['Apples','Bananas','Oranges','They are equal'],'Oranges have the greatest count because 11 is greater than 8 and 5.','Compare the three values.'),
 item('A chart shows Monday: 6 books, Tuesday: 9 books, Wednesday: 7 books. How many more books were read Tuesday than Monday?',3,[1,2,3,15],'9 − 6 = 3, so Tuesday has 3 more books than Monday.','Subtract Monday’s value from Tuesday’s.','number'),
 item('The rule is “add 4”. What comes after 18?',22,[20,21,22,24],'18 + 4 = 22.','Apply the stated rule once.','number'),
]),
'c4_eng_comprehend_main_infer': dict(teach='Use the whole text for the main idea and point to a detail when making an inference. An inference must fit the evidence, not just a guess.', items=[
 item('Leela carried a raincoat. Dark clouds covered the sky, and the wind grew cool. What can you infer?','Rain may be coming',['Rain may be coming','It is very hot and sunny','Leela is going swimming','The sky is cloudless'],'The raincoat, dark clouds and cool wind are details that support the inference that rain may be coming.','Use more than one clue from the text.'),
 item('The class collected bottles, paper and cans for a clean-up drive. What is the main idea?','The class is helping with a clean-up',['The class is helping with a clean-up','The class is baking a cake','The class is learning a dance','The class is buying toys'],'All the details describe collecting items for a clean-up drive.','Ask what all the details have in common.'),
 item('Aman whispered and turned the pages slowly while others read nearby. Where is Aman most likely?','In a library',['In a library','At a loud concert','On a football field','In a swimming pool'],'Whispering, turning pages and other people reading are clues that fit a library.','Choose the place that matches all the clues.'),
 item('Nila checked the soil, then watered only the dry pots. What does this suggest about Nila?','She is checking what the plants need',['She is checking what the plants need','She waters every pot without looking','She is avoiding the plants','She thinks soil cannot be dry'],'Checking the soil before watering shows she is using evidence about what each plant needs.','Use the action before the watering as evidence.'),
]),
'c4_eng_vocab_context': dict(teach='Infer a word from nearby clues, then test the meaning by using the word in another sentence where the same meaning fits.', items=[
 item('The path was narrow, so only one person could walk along it at a time. What does narrow mean?','not wide',['not wide','very noisy','very deep','very bright'],'The clue that only one person could fit shows that narrow means not wide.','Use the space clue in the sentence.'),
 item('Water was scarce, so the hikers shared the little they had. What does scarce mean?','not plentiful',['not plentiful','very cold','easy to find','sweet tasting'],'“The little they had” shows that scarce means not plentiful.','Look for a clue about amount.'),
 item('The puppy was drowsy and kept closing its eyes. What does drowsy mean?','sleepy',['sleepy','angry','hungry','lost'],'Closing its eyes is a clue that drowsy means sleepy.','Use the puppy’s action as a clue.'),
 item('Which sentence uses “scarce” correctly?','During the dry week, clean water became scarce.',['During the dry week, clean water became scarce.','The loud drum was scarce because it made noise.','The square was scarce because it had four sides.','The runner was scarce because she moved quickly.'],'“Clean water became scarce” correctly means that clean water became hard to find or limited.','Use the meaning “not plentiful”.'),
]),
'c4_eng_read_compare': dict(teach='When comparing, identify the same feature in both parts of a text and support the comparison with stated details.', items=[
 item('Riya walks to school. Kabir rides a bicycle. How are their journeys different?','Riya walks while Kabir cycles',['Riya walks while Kabir cycles','Both travel by bus','Both stay at home','Kabir walks and Riya cycles'],'The text states that Riya walks and Kabir rides a bicycle.','Compare the travel method for each person.'),
 item('Mango trees need sunlight. Ferns in this passage grow best in shade. What contrast is stated?','They prefer different light conditions',['They prefer different light conditions','Both need complete darkness','Both are the same plant','Neither needs water'],'The passage contrasts sunlight for mango trees with shade for the ferns.','Compare the light condition named for each plant.'),
 item('Plan A uses two large boxes. Plan B uses four small boxes. Which detail is different?','The number and size of boxes',['The number and size of boxes','Both plans use no boxes','Only the colour is different','The plans are identical'],'The text gives different numbers and sizes of boxes for the two plans.','Point to the quantities and size words.'),
 item('Mina finished first but made two errors. Dev finished later with no errors. Which statement is supported?','Mina was faster, while Dev was more accurate',['Mina was faster, while Dev was more accurate','Dev was faster and less accurate','They had the same speed and accuracy','Neither completed the task'],'Finishing first supports “faster”; making no errors supports “more accurate” for Dev.','Compare one feature at a time: speed, then accuracy.'),
]),
'c4_eng_punctuation': dict(teach='Punctuation helps readers understand sentence boundaries, lists and possession. Edit by checking capitals, end marks, commas and apostrophes.', items=[
 item('Which sentence is punctuated correctly?','We packed apples, bananas and grapes.',['We packed apples bananas and grapes.','We packed apples, bananas and grapes.','we packed apples, bananas and grapes.','We packed apples, bananas and grapes?'],'The sentence begins with a capital, uses a comma to separate list items, and ends with a full stop.','Check the list and the end mark.'),
 item('Which sentence shows possession correctly?','Ravi’s bicycle is blue.',['Ravis bicycle is blue.','Ravi’s bicycle is blue.','Ravis’ bicycle is blue.','ravi’s bicycle is blue.'],'“Ravi’s” uses an apostrophe to show that the bicycle belongs to Ravi.','Look for the apostrophe showing ownership.'),
 item('Which sentence is written correctly?','After lunch, we visited the museum.',['After lunch we visited the museum','after lunch, we visited the museum.','After lunch, we visited the museum.','After lunch? we visited the museum.'],'The introductory phrase is followed by a comma, the sentence starts with a capital and ends with a full stop.','Check the beginning, comma and ending.'),
 item('Which is the correctly punctuated question?','Can we leave now?',['Can we leave now.','can we leave now?','Can we leave now?','Can we leave now!'],'A direct question begins with a capital and ends with a question mark.','Questions end with ?.'),
]),
'c4_evs_food_water': dict(teach='Food and water pass through connected systems before reaching people. Responsible choices reduce waste and protect quality.', items=[
 item('Which sequence best shows a simple food path from farm to home?','Farm → market → home',['Farm → market → home','Home → cloud → farm','Market → moon → home','Farm → river → sky'],'A common simple path is from production at a farm, through a market, to a home.','Put production before selling and using.'),
 item('Which action helps reduce food waste at home?','Take a suitable portion and save leftovers safely',['Take a suitable portion and save leftovers safely','Throw edible food away immediately','Leave food uncovered for days','Buy food only to discard it'],'Taking suitable portions and storing leftovers safely can reduce avoidable food waste.','Choose the action that keeps usable food from being wasted.'),
 item('Why should drinking-water containers be kept clean and covered?','To reduce contamination',['To reduce contamination','To make water salty','To increase litter','To stop all evaporation forever'],'Clean, covered containers help reduce dirt and other contamination entering stored drinking water.','Think about keeping unwanted material out.'),
 item('Which action uses water responsibly while washing vegetables?','Use only the water needed and turn off the tap',['Use only the water needed and turn off the tap','Leave the tap running after finishing','Pour clean water on the floor','Ignore a leaking tap'],'Using only the needed water and turning off the tap reduces waste.','Choose the action that avoids unnecessary flow.'),
]),
'c4_evs_community_interdependence': dict(teach='Communities depend on connected roles and services. One service often relies on other people, supplies or infrastructure to work well.', items=[
 item('A clinic needs medicines delivered from a supplier. What does this show?','Community services depend on other people and services',['Community services depend on other people and services','Clinics never need supplies','Only one job matters','Deliveries stop healthcare'],'The clinic depends on a supplier and delivery service, showing community interdependence.','Look for one service relying on another.'),
 item('Farmers grow vegetables, drivers transport them and shopkeepers sell them. What connects these jobs?','They work in a chain that helps food reach people',['They work in a chain that helps food reach people','They all do exactly the same task','None depends on another','Their work is unrelated'],'Growing, transporting and selling are connected steps that help food reach people.','Put the jobs in the order the food moves.'),
 item('Why are sanitation workers important to a community?','They help keep shared places clean and manage waste',['They help keep shared places clean and manage waste','They control the weather','They make all food','They replace every other service'],'Sanitation work helps keep shared places cleaner and manages waste, supporting community wellbeing.','Think about a service related to cleanliness and waste.'),
 item('A bus service stops because fuel has not arrived. What idea does this illustrate?','One service can depend on supplies from another system',['One service can depend on supplies from another system','Buses do not need resources','All services work alone','Fuel is unrelated to transport'],'Transport depends on resources and supply systems; a disruption can affect another service.','Identify what the bus service needs in order to operate.'),
]),
'c4_ct_visual_abstraction': dict(teach='Abstraction keeps the details needed to solve a problem and leaves out details that do not affect the solution.', items=[
 item('For a robot route map, which detail is essential?','The locations of obstacles',['The locations of obstacles','The robot’s favourite colour','The designer’s birthday','The room’s wall paint'],'Obstacle locations affect whether the robot can travel safely, so they are essential route information.','Keep details that change the route.'),
 item('Which simple representation best helps plan a route through a grid?','Start, goal and blocked cells',['Start, goal and blocked cells','A long story about the robot','A list of unrelated colours','Music notes'],'Start, goal and blocked cells contain the information needed to plan a grid route.','Remove details that do not change movement.'),
 item('A map has roads, a start point, a goal and decorative clouds. Which detail can be removed without changing the route?','Decorative clouds',['Decorative clouds','Roads','Start point','Goal'],'Decorative clouds do not affect the route, while roads, start and goal do.','Ask whether the detail changes the solution.'),
 item('Why is abstraction useful when solving a problem?','It focuses attention on relevant information',['It focuses attention on relevant information','It adds every possible detail','It removes the goal','It makes rules random'],'Abstraction reduces distraction by keeping information that matters to the solution.','Think about relevant versus irrelevant details.'),
]),
},
5:{
'c5_math_large_numbers_100000': dict(teach='Read and compare whole numbers by place value from ten-thousands to ones. Decompose a number to show the value of each digit.', items=[
 item('In 74,215, what value does the digit 7 represent?',70000,[700,7000,70000,74215],'The 7 is in the ten-thousands place, so its value is 70,000.','Name the place of the leftmost digit.','number'),
 item('Which number is 60,000 + 4,000 + 300 + 20 + 5?',64325,[60425,64025,64325,64352],'60,000 + 4,000 + 300 + 20 + 5 = 64,325.','Combine each place value.','number'),
 item('Which number is greater: 58,907 or 58,790?',58907,[58790,58907,58097,58970],'Both start with 58 thousand; 9 hundreds is greater than 7 hundreds, so 58,907 is greater.','Compare from left to right until digits differ.','number'),
 item('A town recorded 96,405 visitors and another recorded 96,450. Which is larger?',96450,[96405,96450,96045,96950],'96,450 is larger because the first differing place is the tens: 5 tens is greater than 0 tens.','Compare the first differing digit.','number'),
]),
'c5_math_estimation': dict(teach='Estimate by rounding to a useful place before exact calculation. Use the estimate to reject answers that are far too large or too small.', items=[
 item('Estimate 398 + 205 by rounding each number to the nearest hundred.',600,[500,600,700,800],'398 rounds to 400 and 205 rounds to 200, so the estimate is 600.','Round each addend to the nearest hundred.','number'),
 item('Which is the best estimate for 1,982 − 1,010?',1000,[100,500,1000,2000],'1,982 is about 2,000 and 1,010 is about 1,000, giving an estimate of about 1,000.','Round to convenient thousands.','number'),
 item('A calculation says 49 × 21 = 10,290. Which statement is best?','The answer is unreasonable; 50 × 20 is about 1,000',['The answer is unreasonable; 50 × 20 is about 1,000','The answer is reasonable because it is above 10,000','No estimate can help','49 × 21 must be below 100'],'49 × 21 is close to 50 × 20 = 1,000, so 10,290 is far too large.','Compare with nearby easy numbers.'),
 item('Estimate 612 ÷ 6 using a nearby compatible number.',100,[10,60,100,600],'612 is close to 600, and 600 ÷ 6 = 100.','Choose a nearby number that divides easily by 6.','number'),
]),
'c5_math_factors_multiples': dict(teach='A factor divides a number exactly. A multiple is made by multiplying that number by a whole number.', items=[
 item('Which number is a factor of 24?',6,[5,6,7,9],'24 ÷ 6 = 4 with no remainder, so 6 is a factor of 24.','Test which choice divides 24 exactly.','number'),
 item('Which number is a multiple of 8?',40,[18,24,40,54],'40 = 8 × 5, so 40 is a multiple of 8.','Look for a number in the 8-times table.','number'),
 item('What is the smallest common multiple of 4 and 6?',12,[8,10,12,24],'Multiples of 4 include 4, 8, 12; multiples of 6 include 6, 12. The smallest common multiple is 12.','List a few multiples of both numbers.','number'),
 item('Which pair are both factors of 36?','4 and 9',['4 and 9','5 and 8','7 and 10','8 and 12'],'36 ÷ 4 = 9 and 36 ÷ 9 = 4, so both 4 and 9 are factors of 36.','Check each number divides 36 exactly.'),
]),
'c5_math_geometry_angles_symmetry': dict(teach='Classify angles by size, use defining shape properties, and reason about symmetry or simple transformations.', items=[
 item('Which angle is acute?','45°',['45°','90°','120°','180°'],'45° is less than 90°, so it is an acute angle.','Acute angles are smaller than a right angle.'),
 item('Which angle is obtuse?','120°',['30°','60°','90°','120°'],'120° is greater than 90° and less than 180°, so it is obtuse.','Compare with a right angle and a straight angle.'),
 item('How many lines of symmetry does a square have?',4,[1,2,3,4],'A square has 4 lines of symmetry: vertical, horizontal and two diagonals.','Imagine folds that make matching halves.','number'),
 item('A shape is turned a quarter-turn around a point. What transformation is this?','Rotation',['Rotation','Reflection','Translation','Measurement'],'Turning a shape around a fixed point is a rotation.','Look for the action “turned around a point”.'),
]),
'c5_math_measure_conversion_volume': dict(teach='Keep units consistent before calculating. Capacity and volume describe how much space or liquid is contained; area measures a surface.', items=[
 item('How many millilitres are in 3 litres?',3000,[300,3000,30000,30],'1 litre is 1,000 mL, so 3 litres is 3,000 mL.','Multiply 1,000 by 3.','number'),
 item('A rectangle is 8 cm long and 5 cm wide. What is its area in square centimetres?',40,[13,26,40,80],'Area of a rectangle = length × width, so 8 × 5 = 40 cm².','Multiply length by width.','number'),
 item('A box holds 24 one-centimetre cubes arranged with no gaps. What is its volume?',24,[6,12,24,48],'Each unit cube has volume 1 cm³, so 24 cubes fill 24 cm³.','Count the unit cubes.','number'),
 item('A bottle holds 2 litres. How many 250 mL cups can it fill?',8,[4,6,8,10],'2 litres is 2,000 mL, and 2,000 ÷ 250 = 8 cups.','Convert litres to millilitres, then divide.','number'),
]),
'c5_math_data': dict(teach='Read labels, scales and values before calculating comparisons. Use only the data shown, not assumptions.', items=[
 item('A table shows Team A: 18 points, Team B: 24, Team C: 21. Which team has the most points?','Team B',['Team A','Team B','Team C','They are equal'],'Team B has 24 points, which is greater than 21 and 18.','Compare all three values.'),
 item('A chart shows 12 books in June and 19 in July. How many more books were read in July?',7,[5,7,12,31],'19 − 12 = 7, so 7 more books were read in July.','Subtract the smaller month value from the larger.','number'),
 item('A table lists Red: 9, Blue: 14, Green: 11. What is the total?',34,[25,32,34,44],'9 + 14 + 11 = 34.','Add the three table values.','number'),
 item('A chart shows Plant A grew 6 cm and Plant B grew 9 cm. Which statement is supported?','Plant B grew 3 cm more than Plant A',['Plant B grew 3 cm more than Plant A','Plant A grew 3 cm more than Plant B','Both grew the same amount','Plant B grew 15 cm more'],'9 − 6 = 3, so Plant B grew 3 cm more.','Compare the two measured values.'),
]),
'c5_eng_comprehend_infer_evidence': dict(teach='An inference combines a reasonable idea with evidence from the text. Choose the inference only when a specific detail supports it.', items=[
 item('Nikhil checked the forecast, packed a raincoat and covered his books in a waterproof bag. What can you infer?','He expects wet weather',['He expects wet weather','He plans to swim indoors','He thinks books cannot get wet','He is preparing for snow only'],'The raincoat and waterproof bag are evidence that Nikhil expects wet weather.','Point to two details that support the inference.'),
 item('The lights were off, the door was locked and a sign said “Back at 2:00”. What is the best inference?','The shop is temporarily closed',['The shop is temporarily closed','The shop is crowded','The shop is open all night','The sign gives no clue'],'The locked door, lights off and return-time sign support the inference that the shop is temporarily closed.','Use all three details together.'),
 item('Priya reread the instructions, corrected one measurement and then the model fit properly. Which detail best supports that checking helped?','After she corrected the measurement, the model fit properly',['She reread the instructions','The model was colourful','After she corrected the measurement, the model fit properly','She worked in the morning'],'The improved result after correcting the measurement directly supports the inference that checking helped.','Choose the detail that links the action to the result.'),
 item('A trail had fresh footprints and bent grass, but no animal was visible. Which inference is best supported?','An animal may have passed recently',['An animal may have passed recently','No animal has ever been there','The grass cannot bend','The footprints were made next year'],'Fresh footprints and bent grass are evidence that an animal may have passed recently.','Infer only what the evidence makes reasonable.'),
]),
'c5_eng_main_summary': dict(teach='A good summary states the central idea and only the most important supporting information. It does not copy every small detail.', items=[
 item('Text: “The class tested three paper-bridge designs. After comparing how much weight each held, they strengthened the best design.” Which is the best summary?','The class tested bridge designs and improved the strongest one',['The class tested bridge designs and improved the strongest one','Three pieces of paper were on a table','The class likes bridges because bridges are long','Every tiny step of the test must be listed'],'The best summary gives the central action—testing designs—and the important result—improving the strongest one.','Keep the main action and result, not every detail.'),
 item('Text: “Meera planted native flowers. Soon more bees visited the garden, so she added another flower bed.” What is the main idea?','Planting native flowers attracted bees and encouraged Meera to plant more',['Planting native flowers attracted bees and encouraged Meera to plant more','Meera bought a new bicycle','Bees never visit flowers','The garden had no plants'],'The main idea connects the planting, increased bee visits and Meera’s decision to plant more.','Connect the cause and result across the whole text.'),
 item('Which summary is most concise for a passage about students measuring rainfall each day and comparing the weekly totals?','Students recorded daily rainfall and compared weekly totals',['Students recorded daily rainfall and compared weekly totals','Students used a blue ruler on Monday, a pencil on Tuesday, and many other tiny details','Rain is water and weeks have days','Students did nothing with measurements'],'The concise summary keeps the main actions: recording rainfall and comparing totals.','Remove minor details that do not change the main idea.'),
 item('A passage explains that a village repaired leaks, collected rainwater and used less water during dry months. Which summary fits best?','The village used several methods to conserve water',['The village used several methods to conserve water','The village wanted to waste more water','Only one person saw a cloud','The passage is mainly about road traffic'],'Repairing leaks, collecting rainwater and reducing use are all methods of water conservation.','Find one idea that covers all three actions.'),
]),
'c5_eng_vocab_morphology_context': dict(teach='Use context together with familiar prefixes, roots or suffixes. Check that the inferred meaning fits the whole sentence.', items=[
 item('In “The glass was reusable, so we washed it and used it again,” what does reusable mean?','able to be used again',['able to be used again','impossible to clean','made only of paper','used only once'],'The suffix “-able” suggests “able to”, and the sentence says the glass was used again.','Combine the word part with the context clue.'),
 item('In “Maya reread the note because she missed one line,” what does the prefix re- mean in reread?','again',['again','before','without','under'],'The prefix re- means again; Maya read the note another time.','Look at the action described after “because”.'),
 item('In “The path was uneven, with bumps and dips,” what does uneven mean?','not level or smooth',['not level or smooth','perfectly flat','very bright','full of water'],'The prefix un- means “not”, and bumps and dips show that the path is not level or smooth.','Use both the prefix and the examples.'),
 item('Which sentence uses “careless” correctly?','Ravi made a careless mistake because he did not check his work.',['Ravi made a careless mistake because he did not check his work.','The careful pilot was careless because every check was completed','A triangle is careless because it has three sides','The water was careless because it froze'],'“-less” can mean “without”; a mistake made without enough care fits the word careless.','Use the base word “care” and suffix “-less”.'),
]),
'c5_eng_punctuation_editing': dict(teach='Edit a sentence by checking capitals, end marks, commas, apostrophes and obvious agreement. Change only what is needed for meaning and correctness.', items=[
 item('Which edited sentence is correct?','After the rain stopped, we walked to the park.',['after the rain stopped we walked to the park','After the rain stopped, we walked to the park.','After the rain stopped? we walked to the park.','After the rain stopped, We walked to the park.'],'The sentence begins with a capital, uses a comma after the introductory clause and ends with a full stop.','Check the beginning, comma and end mark.'),
 item('Which sentence uses the apostrophe correctly?','The children’s books are on the shelf.',['The childrens books are on the shelf.','The children’s books are on the shelf.','The childrens’ books are on the shelf.','The children,s books are on the shelf.'],'“Children” is already plural, so “children’s” uses ’s to show possession.','The plural word is “children”, not “childrens”.'),
 item('Which sentence is edited correctly?','Ravi and Meena are preparing their project.',['Ravi and Meena is preparing their project.','ravi and Meena are preparing their project','Ravi and Meena are preparing their project.','Ravi and Meena are preparing there project.'],'The compound subject takes “are”, both names are capitalised and “their” correctly shows possession.','Check agreement, capitals and the word their.'),
 item('Which sentence is punctuated correctly?','“Please close the gate,” said Arjun.',['“Please close the gate” said Arjun.','“Please close the gate,” said Arjun.','“please close the gate,” said Arjun.','Please close the gate,” said Arjun.'],'The spoken words begin with a capital and the comma is placed inside the closing quotation mark before “said Arjun”.','Check the quotation marks, capital and comma.'),
]),
'c5_eng_explain_justify': dict(teach='A strong explanation states a clear idea and supports it with a relevant reason or evidence. Check that the reason actually supports the claim.', mastery=False, items=[
 item('Which response best justifies the idea “The class should keep a reading corner”?','Yes, because easy access to books gives students more chances to read.',['Yes, because easy access to books gives students more chances to read.','Yes, because I said yes.','Books have pages.','The class has walls.'],'The response states the idea and gives a relevant reason connected to reading opportunities.','Look for a reason that directly supports the idea.'),
 item('Which explanation is strongest for “We should repair the leaking tap”?','Repairing it prevents unnecessary water loss.',['Repairing it prevents unnecessary water loss.','The tap is near a wall.','Water is wet.','I like blue taps.'],'Preventing unnecessary water loss is a relevant reason for repairing a leak.','Choose a reason linked to the problem.'),
 item('Which answer includes both a claim and evidence?','The plant grew better in sunlight because it gained 4 cm compared with 1 cm in shade.',['The plant grew better in sunlight because it gained 4 cm compared with 1 cm in shade.','Plants are interesting.','Sunlight is bright.','The ruler was green.'],'The sentence makes a claim and supports it with measured evidence from the comparison.','Look for both an idea and a supporting measurement.'),
 item('Which justification is most relevant to choosing the shorter safe route?','Route B is better because it is safe and is 200 metres shorter.',['Route B is better because it is safe and is 200 metres shorter.','Route B has a nice name.','I chose it without looking at the map.','Routes can be drawn with lines.'],'Safety plus the measured shorter distance directly supports the choice of Route B.','Use evidence that matches the decision.'),
]),
'c5_evs_food_water_community': dict(teach='Food and water systems connect natural resources, livelihoods, transport, public services and community wellbeing. Responsible decisions consider those links.', items=[
 item('A farming area has very little irrigation water. Which effect is most directly possible?','Crop production may decrease',['Crop production may decrease','Road signs disappear','All houses become taller','The day becomes longer'],'Less irrigation water can reduce the water available to crops, which may decrease production.','Trace the resource to the activity that depends on it.'),
 item('Why can a clean local water supply support community wellbeing?','It supports drinking, hygiene and daily activities',['It supports drinking, hygiene and daily activities','It makes all people do the same job','It removes the need for food','It guarantees there will never be drought'],'Reliable clean water supports essential daily needs such as drinking and hygiene.','Connect the resource to everyday needs.'),
 item('Farmers grow vegetables, drivers transport them and vendors sell them. What does this show?','Food systems connect several livelihoods',['Food systems connect several livelihoods','Only farmers are part of food systems','Transport has no role in food access','Vendors grow every crop they sell'],'Production, transport and selling are linked livelihoods within a food system.','Follow the food from production to people.'),
 item('Which community action best protects a shared water source?','Keep waste out of it and report pollution',['Keep waste out of it and report pollution','Dump rubbish beside it','Leave leaks unrepaired','Use it as a waste bin'],'Keeping waste out and reporting pollution helps protect water quality for the community.','Choose the action that reduces contamination.'),
]),
}}

ACTIVITY_KINDS=[('g1','guidedPractice',4),('i1','independentPractice',4),('m1','masteryCheck',5),('t1','transfer',5)]

def slug(cid): return re.sub(r'^c[345]_', '', cid)

def text_choice_distractors(answer, choices):
    return [{'value':v,'misconceptionId':'phase_e_choice_distractor'} for v in choices if v!=answer]

def generate():
    curriculum=json.loads((ROOT/'assets/content/curriculum_map.json').read_text())
    for clsno, specs in SPECS.items():
        c=next(x for x in curriculum['classes'] if x['classNumber']==clsno)
        comps={x['id']:x for x in c['competencies']}
        outcomes={x['competencyId']:x for x in c['learningOutcomes']}
        pack_path=ROOT/f'assets/content/class_{clsno}/pack.json'
        pack=json.loads(pack_path.read_text())
        # Remove any prior Phase E content for idempotence.
        pack['activities']=[a for a in pack['activities'] if a.get('gameId')!='skill_studio']
        existing_ids={a['id'] for a in pack['activities']}
        new_acts=[]
        phase_mappings=[]
        for idx,(cid,spec) in enumerate(specs.items(),1):
            comp=comps[cid]; outcome=outcomes[cid]
            s=slug(cid)
            topic=f'phase_e_{s}'
            mapping={
                'id':f'c{clsno}_phase_e_map_{idx:02d}',
                'gameId':'skill_studio','topicId':topic,'competencyIds':[cid],
                'disposition':'mapped','boundaryStatus':'pendingHumanReview',
                'review':{'status':'needsReview','revision':1,'author':'brightquest-phase-e-technical-hardening','reviewerOwnerId':'primary_teacher_reviewer','reviewedAt':None},
            }
            phase_mappings.append(mapping)
            mastery=spec.get('mastery',True)
            ids=[]
            for (suffix,atype,diff), qspec in zip(ACTIVITY_KINDS,spec['items']):
                aid=f'c{clsno}_skill_studio_{s}_{suffix}'
                assert aid not in existing_ids
                ids.append(aid)
                answer=qspec['answer']; choices=qspec['choices']
                case_sensitive = cid in {
                    'c3_eng_punctuation_capitals',
                    'c4_eng_punctuation',
                    'c5_eng_punctuation_editing',
                }
                rule_type = (
                    'exactNumber' if qspec['kind'] == 'number'
                    else 'exactTextCaseSensitive' if case_sensitive
                    else 'exactText'
                )
                rule={'type':rule_type,'value':answer}
                payload={'answer':answer,'choices':choices,'hint':qspec['hint'],'masteryEligible':mastery,'evidenceScope':'full' if mastery else 'practiceOnlyConstructedResponsePending'}
                act={
                    'id':aid,'legacyContentId':f'pe_{s}_{suffix}','classNumber':clsno,'gameId':'skill_studio','topicId':topic,
                    'subject':comp['subject'],'unitId':comp['unitId'],'competencyId':cid,'relatedCompetencyIds':[],
                    'learningOutcomeId':outcome['id'],'relatedLearningOutcomeIds':[],'activityType':atype,'difficulty':diff,
                    'prompt':qspec['q'],'correctResponseRule':rule,'explanation':qspec['explanation'],
                    'distractors':text_choice_distractors(answer,choices),'hints':[{'step':1,'text':qspec['hint']}],
                    'narration':{'text':qspec['q']},'locale':'en-IN','author':'brightquest-phase-e-technical-hardening',
                    'reviewerOwnerId':'primary_teacher_reviewer','status':'needsReview','revision':1,
                    'generation':{'mode':'authored','deterministicSeed':None},'payload':payload,
                }
                new_acts.append(act)
            # update blueprint
            bp_path=ROOT/f'assets/content/class_{clsno}/learning_blueprints.json'
            # loaded below once; store ids/spec on temporary dict
            spec['_ids']=ids
        pack['activities'].extend(new_acts)
        pack['packVersion']='1.1.0'
        pack_path.write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')
        # Replace prior phase-e mappings and append.
        c['currentContentMappings']=[m for m in c['currentContentMappings'] if not str(m.get('id','')).startswith(f'c{clsno}_phase_e_map_')]
        c['currentContentMappings'].extend(phase_mappings)

        bp_path=ROOT/f'assets/content/class_{clsno}/learning_blueprints.json'
        bpdoc=json.loads(bp_path.read_text())
        byid={b['competencyId']:b for b in bpdoc['blueprints']}
        for cid,spec in specs.items():
            bp=byid[cid]; ids=spec['_ids']; first=spec['items'][0]
            bp['teach']=spec['teach']
            bp['workedExample']=f"{first['q']} {first['explanation']}"
            bp['guidedTry']={'prompt':first['q'],'hintLevel1':first['hint'],'hintLevel2':first['explanation']}
            bp['independentPractice']={'sourceActivityIds':[ids[1],ids[2]],'fallbackPrompt':spec['items'][1]['q']}
            bp['masteryTransfer']={'requireUnseenWording':True,'hintAllowed':False,'prompt':spec['items'][3]['q']}
            bp['reviewPrompt']=f"Later, try a fresh {bp['title'].lower()} task and explain the clue, rule or evidence you used."
            bp['narrationText']=spec['teach']
            review=bp.get('review',{})
            review.update({'status':'needsReview','revision':max(2,int(review.get('revision',1))),'author':'brightquest-phase-e-technical-hardening','reviewerOwnerId':'primary_teacher_reviewer','reviewedAt':None})
            bp['review']=review
        # Harden generic transfer/review language for every other blueprint without pretending review approval.
        for bp in bpdoc['blueprints']:
            if bp['competencyId'] in specs: continue
            subj=bp['subject']; title=bp['title']
            transfer={
                'maths':f'Solve a fresh {title.lower()} situation, then check the result with a second method, model or estimate.',
                'english':f'Use {title.lower()} in a fresh text or sentence and point to the words that support your answer.',
                'science':f'Apply {title.lower()} to a new observation and identify the evidence that supports your answer.',
                'evs':f'Apply {title.lower()} to a new everyday situation and explain the responsible or evidence-based choice.',
                'social':f'Apply {title.lower()} to a new map or community example and identify the clue that supports your answer.',
                'coding':f'Use {title.lower()} on a new route or problem, then trace the steps to check that the solution works.',
            }[subj]
            bp['masteryTransfer']={'requireUnseenWording':True,'hintAllowed':False,'prompt':transfer}
            bp['reviewPrompt']=f'Later, solve a different {title.lower()} task without copying the earlier example, then explain how you checked it.'
            review=bp.get('review',{})
            review.update({'status':'needsReview','revision':max(2,int(review.get('revision',1))),'author':'brightquest-phase-e-technical-hardening','reviewerOwnerId':'primary_teacher_reviewer','reviewedAt':None})
            bp['review']=review
        bpdoc['status']='needsReview'
        bp_path.write_text(json.dumps(bpdoc,ensure_ascii=False,indent=2)+'\n')

    (ROOT/'assets/content/curriculum_map.json').write_text(json.dumps(curriculum,ensure_ascii=False,indent=2)+'\n')

    # Fix known teacher-facing ambiguities/incomplete explanations in existing content.
    grammar_replacements={
      'c3_grammar_puzzle_grammar3_5':('A gentle breeze blows.','breeze','blows','gentle'),
      'c3_grammar_puzzle_grammar3_6':('The colourful butterfly flutters.','butterfly','flutters','colourful'),
      'c4_grammar_puzzle_grammar4_5':('A powerful river rushes.','river','rushes','powerful'),
      'c4_grammar_puzzle_grammar4_6':('The patient gardener waits.','gardener','waits','patient'),
      'c5_grammar_puzzle_grammar5_3':('The ancient monument stands.','monument','stands','ancient'),
      'c5_grammar_puzzle_grammar5_4':('The careful scientist observes.','scientist','observes','careful'),
      'c5_grammar_puzzle_grammar5_5':('The enormous telescope rotates.','telescope','rotates','enormous'),
      'c5_grammar_puzzle_grammar5_6':('A determined athlete trains.','athlete','trains','determined'),
    }
    for clsno in [3,4,5]:
      path=ROOT/f'assets/content/class_{clsno}/pack.json'; pack=json.loads(path.read_text())
      for a in pack['activities']:
        if a['id'] in grammar_replacements:
          sent,noun,verb,adj=grammar_replacements[a['id']]
          a['prompt']=sent; a['narration']['text']=sent
          a['correctResponseRule']={'type':'grammarParts','noun':noun,'verb':verb,'adjective':adj}
          a['payload'].update({'sentence':sent,'noun':noun,'verb':verb,'adjective':adj})
          a['explanation']=f'In this sentence, “{noun}” is the noun, “{verb}” is the verb, and “{adj}” is the adjective.'
          a['revision']=max(2,a.get('revision',1)); a['author']='brightquest-phase-e-technical-hardening'
        if a['id']=='c3_math_market_q04':
          a['hints']=[{'step':1,'text':'Split 75 into 25 + 50. First make 150, then add 50.'}]
          a['payload']['hint']='Split 75 into 25 + 50. First make 150, then add 50.'
          a['explanation']='125 + 75 = 125 + 25 + 50 = 150 + 50 = 200.'
          a['revision']=max(2,a.get('revision',1)); a['author']='brightquest-phase-e-technical-hardening'
        if a['id']=='c3_map_quest_map3_2':
          a['prompt']='The park is north of your school. Which way do you travel?'; a['narration']['text']=a['prompt']; a['revision']=max(2,a.get('revision',1)); a['author']='brightquest-phase-e-technical-hardening'
        if a['gameId']=='recycling_challenge':
          name=a['payload']['name']; binv=a['payload']['bin']
          a['explanation']=f'In this BrightQuest material-sorting practice, {name} goes in the {binv} group. Real local recycling rules can differ.'
          a['revision']=max(2,a.get('revision',1)); a['author']='brightquest-phase-e-technical-hardening'
      path.write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__': generate()
