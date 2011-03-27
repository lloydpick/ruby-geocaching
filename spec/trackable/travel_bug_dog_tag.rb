# encoding: utf-8

describe "Geocaching::Trackable for 0e421f14-018e-40a2-bbe1-bb43a9441e9c (Travel Bug Dog Tag)" do
  before :all do
    @trackable = Geocaching::Trackable.fetch(:guid => "0e421f14-018e-40a2-bbe1-bb43a9441e9c")
  end

  it "should return the correct TB code" do
    @trackable.code.should == "TB3EM3X"
  end

  it "should return the correct name" do
    @trackable.name.should == "Pirates of the Caribbean"
  end

  it "should return the correct displayed owner name" do
    @trackable.owner_display_name.should == "lloydpick"
  end

  it "should return the correct owner GUID" do
    @trackable.owner.guid.should == "daf07e55-660f-4d4c-9c34-0e901a8f7198"
  end

  it "should return the correct trackable type" do
    @trackable.type.to_sym.should == :travel_bug_dog_tag
  end

  it "should return the correct release date" do
    @trackable.released_at.should == Time.mktime(2010, 06, 11)
  end

  it "should return the correct origin" do
    @trackable.origin.should == "London, United Kingdom"
  end
  
  it "should return the cache or user it is currently with" do
    @trackable.last_spotted.guid.should == "6bb9bd20-f75d-42a0-bfc7-d1033040f480"
  end
  
  it "should return a goal" do
    @trackable.goal.should == "To visit and maybe ride the Pirates of the Caribbean in Disneyland Japan. <br>\r (<a href=\"http://www.tokyodisneyresort.co.jp/tdl/english/7land/adventure/atrc_carib.html\" target=\"_blank\" rel=\"nofollow\">visit link</a>) <br><br>Upon reaching the destination I'd like to ride it, a photo, then if possible, find the nearest kid who's got some pins and trade the pin for another ride pin, preferably which exists in another Disney park so it can continue onwards!"
  end
  
  it "should return an about section" do
    @trackable.about.should == "The pin originally came from Disneyland Paris, so it only seems fitting to send it to one of the other Disney parks! Hopefully once it gets there, this pin will change into a different ride, and then it journey shall begin again!"
  end

  it "should return a plausible tracking distance history" do
    @trackable.distance_travelled.should >= 900
  end

end
