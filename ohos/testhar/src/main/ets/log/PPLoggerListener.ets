
// PpLoggerListener.ets
export interface  PPLoggerListener {
  d?:(msg: string)=> void;

  e?:(msg: string)=> void;

  i?:(msg: string)=> void;

  w?:(msg: string)=> void;

}