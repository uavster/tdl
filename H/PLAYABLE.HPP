#ifndef __PLAYABLE_INCLUDED__
#define __PLAYABLE_INCLUDED__

class Playable {
public:
	Playable() : last_error_(kSuccess) {}
	
	virtual bool Play() = 0;
	virtual void Pause() = 0;
	virtual void Stop() = 0;
	virtual void Volume(float volume) = 0;
	virtual float Volume() = 0;
	virtual void Forward() = 0;
	virtual void Backward() = 0;

	enum ErrorCode { kSuccess, kCantLoad, kCantAllocateMixerChannels, kCantAddMixerCallback };
	ErrorCode LastError() const { return last_error_; }
	ErrorCode LastError(ErrorCode new_error) { return last_error_ = new_error; }
	
private:
	ErrorCode last_error_;
};

#endif