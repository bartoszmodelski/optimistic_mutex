#include <atomic>
#include <iostream>
#include <caml/mlvalues.h>
#include <caml/gc.h>

extern "C"
{
    CAMLprim value caml_suspend_resume_make(value unit)
    {
        std::atomic<int> *atomic_ptr = new std::atomic<int>();
        *atomic_ptr = 0;

        return (value)atomic_ptr;
    }

    CAMLprim value caml_suspend_resume_free(value arg1)
    {
        std::atomic<int> *atomic_ptr = (std::atomic<int> *)arg1;
        delete atomic_ptr;

        return Val_unit;
    }

    CAMLprim value caml_suspend_resume_wait(value arg1)
    {
        std::atomic<int> *atomic_ptr = (std::atomic<int> *)arg1;
        atomic_ptr->wait(0);

        return Val_unit;
    }

    CAMLprim value caml_suspend_resume_notify(value arg1)
    {
        std::atomic<int> *atomic_ptr = (std::atomic<int> *)arg1;
        *atomic_ptr = 1;
        atomic_ptr->notify_one();

        return Val_unit;
    }
}