require 'Rubbit'
require 'mongo'
require 'io/console'

include Mongo

r = Rubbit.new 'Randybot'
r.set_request_period(2)

r.login
puts

client = MongoClient.new('ds053130.mongolab.com',53130)

db = client.db('randybot')

print('Enter Database username: ')
db_user = gets.chomp
print('Enter Database password: ')
db_pass = passwd = STDIN.noecho(&:gets).chomp
db.authenticate(db_user,db_pass)
puts
@coll = db.collection('responses')

permitted_subs = [nil,'CenturyClub']
@wakeup = '/u/' + r.me.name.downcase + ':'
@post_text = "\n\n ^^This ^^comment ^^was ^^made ^^by ^^a ^^bot. ^^To ^^report ^^errors, ^^please [^^pm ^^me](https://www.reddit.com/message/compose?to=" + r.me.name + "&subject=Bot-problems)^^."

@handled = []

def set_response(input,output)
	if(@coll.find({'input'=>input}).to_a.length > 0)
		return 'This input is taken.'
	else
		@coll.insert({'input'=>input,'output'=>output})
		return 'Response set.'
	end
end

def get_response(input)
	if(input=='list')
		response = @coll.find({'input'=>//}).to_a
		to_return = "My current list of commands are:\n\n____\n\n"
		response.each do |r|
			to_return += "* " + r['input']+ "\n\n"
		end
		to_return+="____"
		return to_return
	end
	response =  @coll.find({'input'=>input}).to_a
	if(response.length == 0)
		return 'This input is not yet set.'
	else
		return response[0]['output']
	end
end

def push_handled(id)
	@handled.insert(0,id)
	if(@handled.length>50)
		@handled.pop
	end
	return
end

def handle(comment)
	body = comment.body[@wakeup.length..-1].strip
	downcase_body = body.downcase
	to_respond = ''
	if(downcase_body.index('input:')==0 and downcase_body.index('output:')!= nil)
		input = body[0..downcase_body.index('output:')-1].downcase
		input = input['input:'.length..-1].strip
		output = body[downcase_body.index('output:')..-1].strip
		output = output['output:'.length..-1].strip
		puts comment.author + " tried to set command: \n" + input + " : " + output
		to_respond = set_response(input,output)
	else
		to_respond = get_response(body.downcase)
	end
	comment.reply(to_respond + @post_text)
end

inbox = r.get_inbox(25)
inbox.each do |c|
	push_handled(c.name)
end

while(true)
	inbox = r.get_inbox(25)
	inbox.each do |c|
		if(not (@handled.include? c.name) and ( permitted_subs.include? c.subreddit ))
			push_handled(c.name)
			if(c.body.downcase.index(@wakeup))
				handle(c)
			end
		end
	end
end